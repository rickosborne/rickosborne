<?php
namespace Org\Corfield;

class FW1Obj {
	private $properties = array();
	// this is a helper class needed to work around pass-by-value
	// problems in some versions of PHP
	public function __get($property) {
		if ($this->exists($property)) {
			return $this->properties[$property];
		}
		return NULL;
	}
	public function __set($property, $value) {
		$this->properties[$property] = $value;
	}
	public function param($property, $default) {
		if (!$this->exists($property)) {
			$this->properties[$property] = $default;
		}
		return $this->properties[$property];
	}
	public function exists($property) {
		return array_key_exists($property, $this->properties);
	}
	public function delete($property) {
		if($this->exists($property)) {
			unset($this->properties[$property]);
		}
	}
	
	public function dump() {
		print '<table class="debug">' . "\n";
		foreach ($this->properties as $key => $value) {
			print '<tr><td class="key">' . htmlentities($key) . '</td><td class="value">' . (is_scalar($value) ? htmlentities($value) : '[' . gettype($value) . ']') . "</td></tr>\n";
		}
		print "</table>\n";
	}
}

class Framework1 {
	
	protected $context;
	protected $framework;
	protected $request;
	protected $cache;
	protected $cgiScriptFileName;
	protected $cgiScriptName;
	protected $cgiPathInfo;
	protected $appRoot;
	
	public function __construct($settings) {
		$this->cgiScriptName = self::arrayParam($_SERVER, 'SCRIPT_NAME');
		$this->cgiPathInfo = self::arrayParam($_SERVER, 'PATH_INFO');
		$this->cgiScriptFileName = self::arrayParam($_SERVER, 'SCRIPT_FILENAME');
		$this->appRoot = dirname($this->cgiScriptFileName) . '/';
		$this->basePath = dirname($this->cgiScriptName) . '/';
		$this->context   = new FW1Obj();
		$this->framework = new FW1Obj();
		$this->request   = new FW1Obj();
		$this->cache     = new FW1Obj();
		try {
			$this->setupFrameworkDefaults($settings);
			$this->onRequestStart($this->cgiScriptName);
			$this->onRequest($this->cgiScriptName);
		}
		catch(\Exception $ex) {
			$this->onError($ex);
		}
	} // ctor
	
	public function __get($property) {
		if ($property === 'appRoot')
			return $this->appRoot;
		elseif ($property === 'baseUrl')
			return $this->framework->baseUrl;
		elseif ($property === 'scriptName')
			return $this->cgiScriptName;
		return NULL;
	} // get
	
	protected static function arrayParam(&$arr, $key, $def = '') {
		return array_key_exists($key, $arr) ? $arr[$key] : $def;
	} // arrayParam
	
	public function buildUrl($action, $path = NULL, $queryString = '', $literal = FALSE) {
		if (is_null($path)) {
			$path = $this->framework->baseUrl;
		}
		if (is_null($queryString)) {
			$queryString = '';
		}
		$omitIndex = FALSE;
		if ($path === 'useCgiScriptName') {
			$path = $this->cgiScriptName;
			if ($this->framework->SESOmitIndex) {
				$path = dirname($path) . '/';
				$omitIndex = TRUE;
			}
		}
		if ((strpos($action, '?') !== FALSE) && ($queryString === '')) {
			$queryString = substr($action, strpos($action, '?'));
			$action = substr($action, 0, min(strpos($action, '?'), strpos($action, '#')));
		}
		if (substr($action, 0, 2) === './') {
			$literal = TRUE;
			$cosmeticAction = substr($action, 2);
		} else {
			$cosmeticAction = $this->getSectionAndItem($action);
		}
		$isHomeAction = ($cosmeticAction === $this->getSectionAndItem($this->framework->home));
		$isDefaultItem = ($this->getItem($cosmeticAction) === $this->framework->defaultItem);
		$initialDelim = '?';
		$varDelim = '&';
		$equalDelim = '=';
		$ses = FALSE;
		$anchor = '';
		$extraArgs = '';
		if (strpos($path, '?') !== FALSE) {
			if ((substr_compare($path, '?', strlen($path) - 1) === 0) || (substr_compare($path, '&', strlen($path) - 1) === 0)) {
				$initialDelim = '';
			} else {
				$initialDelim = '&';
			}
		} elseif ($this->framework->exists('generateSES') && ($this->framework->generateSES)) {
			if ($omitIndex) {
				$initialDelim = '';
			} else {
				$initialDelim = '/';
			}
			$varDelim = '/';
			$equalDelim = '/';
			$ses = TRUE;
		}
		$curDelim = $varDelim;
		$queryPart = '';
		if ($queryString !== '') {
			$qAt = strpos($queryString, '?');
			$hashAt = strpos($queryString, '#');
			$qAt = ($qAt === FALSE) ? strlen($queryString) : $qAt;
			$hashAt = ($hashAt === FALSE) ? strlen($queryString) : $hashAt;
			$extraArgs = substr($queryString, 0, min($qAt, $hashAt));
			if (strpos($queryString, '?') !== FALSE) {
				$queryPart = substr($queryString, strpos($queryString, '?'));
			}
			if (strpos($queryString, '#') !== FALSE) {
				$anchor = substr($queryString, strpos($queryString, '#'));
			}
			if ($ses) {
				$extraArgs = str_replace('=', '/', str_replace('&', '/', $extraArgs));
			}
		}
		$basePath = '';
		if ($ses) {
			if ($isHomeAction && ($extraArgs === '')) {
				$basePath = $path; 
			} elseif ($isDefaultItem && ($extraArgs === '')) {
				$basePath  = $path . $initialDelim . array_shift(explode($cosmeticAction, '.', 2));
			} elseif ($literal === TRUE) {
				$basePath  = $path . $initialDelim . $cosmeticAction;
			} else {
				$basePath  = $path . $initialDelim . str_replace('.', '/', $cosmeticAction);
			}
		} else {
			if ($isHomeAction) {
				$basePath = $path;
				$curDelim = '?';
			} else if ($isDefaultItem) {
				$basePath = $path . $initialDelim . $this->framework->action . $equalDelim . array_shift(explode($cosmeticAction, '.', 2));
			} else {
				$basePath = $path . $initialDelim . $this->framework->action . $equalDelim . $cosmeticAction;
			}
		}
		if ($extraArgs !== '') {
			$basePath .= $curDelim . $extraArgs;
			$curDelim = $varDelim;
		}
		if ($queryPart !== '') {
			if ($ses) {
				$basePath .= '?' . $queryPart;
			} else {
				$basePath .= $curDelim . $queryPart;
			}
		}
		if ($anchor !== '') {
			$basePath .= '#' . $anchor;
		}
		return $basePath;
	} // buildUrl
	
	protected function buildViewAndLayoutQueue() {
		$siteWideLayoutBase = $this->request->base;
		$section = $this->request->section;
		$item = $this->request->item;
		if ($this->request->exists('overrideViewAction')) {
			$section = $this->getSection($this->request->overrideViewAction);
			$item = $this->getItem($this->request->overrideViewAction);
		}
		$subsystemBase = $this->request->base;
		$this->request->view = $this->parseViewOrLayoutPath($section . '/' . $item, 'view');
		if (!$this->cachedFileExists($this->request->view)) {
			$this->request->missingView = $this->request->view;
			$this->request->delete('view');
		}
		$this->request->layouts = array();
		$testLayout = $this->parseViewOrLayoutPath($section . '/' . $item, 'layout');
		if ($this->cachedFileExists($testLayout)) {
			$layouts = $this->request->layouts;
			$layouts[] = $testLayout;
			$this->request->layouts = $layouts;
		}
		$testLayout = $this->parseViewOrLayoutPath($section, 'layout');
		if ($this->cachedFileExists($testLayout)) {
			$layouts = $this->request->layouts;
			$layouts[] = $testLayout;
			$this->request->layouts = $layouts;
		}
		if ($this->request->section !== 'default') {
			$testLayout = $this->parseViewOrLayoutPath('default', 'layout');
			if ($this->cachedFileExists($testLayout)) {
				$layouts = $this->request->layouts;
				$layouts[] = $testLayout;
				$this->request->layouts = $layouts;
			}
		}
	} // buildViewAndLayoutQueue
	
	protected function cachedFileExists($filePath) {
		if (!$this->framework->cacheFileExists) {
			return file_exists($filePath);
		}
		$exists = $this->cache->exists('fileExists') ? $this->cache->fileExists : array();
		if (!array_key_exists($filePath, $exists)) {
			$exists[$filePath] = file_exists($filePath);
			$this->cache->fileExists = $exists;
		}
		return $exists[$filePath];
	} // cachedFileExists
	
	public function controller($action) {
		$section = self::getSection($action);
		$item    = self::getItem($action);
		if (array_key_exists('controllerExecutionStarted', $this->request)) {
			throw new \Exception("Controller '$action' may not be added at this point.");
		}
		$tuple = array(
			'controller' => $this->getController($section),
			'key'        => $section,
			'item'       => $item
		);
		if (is_object($tuple['controller'])) {
			$this->request->param('controllers', array());
			$controllers = $this->request->controllers;
			array_push($controllers, $tuple); 
			$this->request->controllers = $controllers;
		}
	} // controller
	
	public function customizeViewOrLayoutPath($pathInfo, $type, $fullPath) {
		return $fullPath;
	} // customizeViewOrLayoutPath
	
	protected function doController($obj, $method) {
		$reflect = new \ReflectionClass(get_class($obj));
		if($reflect->hasMethod($method) && $reflect->getMethod($method)->isPublic()) {
		// if (is_callable(array($obj, $method))) {
			$obj->{$method}($this->context);
			// call_user_func_array(array($obj, $method), $this->context);
		} else {
			// print "Method '$method' is not available for controller '" . get_class($obj) . "'.";
		}
	} // doController
	
	protected function doService($obj, $method, $args, $enforceExistence) {
		$reflect = new \ReflectionClass(get_class($obj));
		if($reflect->hasMethod($method) && $reflect->getMethod($method)->isPublic()) {
		// if (is_callable(array($obj, $method))) {
			// return $obj->{$method}($args);
			return call_user_func_array(array($obj, $method), $args);
		} elseif ($enforceExistence) {
			throw new \Exception("Service method '$method' does not exist in service '" . get_class($obj) . "'.");
		}
	} // doService
	
	protected function failure($ex) {
		print "<h1>Error</h1>";
		if ($this->request->exists('failedAction')) {
			$fa = $this->request->failedAction;
			print "<p>The action $fa failed.</p>";
		}
		print "<p>" . htmlentities($ex->getMessage()) . "</p>";
	} // failure
	
	protected function getCachedObject($type, $section) {
		$types = $type . 's';
		$classKey = $section;
		$baseDir = $this->appRoot;
		if (!array_key_exists($classKey, $this->cache->{$types})) {
			$reqPath = $baseDir . $types . '/' . $section . '.php';
			if ($this->cachedFileExists($reqPath)) {
				require_once($reqPath);
				$classPath = '\\' . $types . '\\' . $section;
				if ($type === 'controller') {
					$obj = new $classPath($this);
				} else {
					$obj = new $classPath();
				}
				if (is_object($obj)) {
					$typeCache = $this->cache->{$types};
					$typeCache[$classKey] = $obj; 
					$this->cache->{$types} = $typeCache;
				}
			}
		}
		if (array_key_exists($classKey, $this->cache->{$types})) {
			return $this->cache->{$types}[$classKey];
		}
		return NULL;
	} // getCachedObject
	
	protected function getController($section) {
		return $this->getCachedObject('controller', $section); 
	} // getController
	
	protected function getItem($action) {
		return array_pop(explode('.', $this->getSectionAndItem($action), 2));
	} // getItem
	
	protected function getNextPreserveKeyAndPurgeOld() {
		$oldKeyToPurge = '';
		session_start();
		if ($this->framework->maxNumContextsPreserved > 1) {
			if (!array_key_exists('__fw1NextPreserveKey', $_SESSION)) {
				$_SESSION['__fw1NextPreserveKey'] = 1;
			}
			$nextPreserveKey = $_SESSION['__fw1NextPreserveKey'];
			$_SESSION['__fw1NextPreserveKey']++;
			$oldKeyToPurge = $nextPreserveKey - $this->framework->maxNumContextsPreserved;
		} else {
			$_SESSION['__fw1NextPreserveKey'] = '';
			$nextPreserveKey = '';
			$oldKeyToPurge = '';
		}
		if (array_key_exists($this->getPreserveKeySessionKey($oldKeyToPurge), $_SESSION)) {
			unset($_SESSION[$this->getPreserveKeySessionKey($oldKeyToPurge)]);
		}
		return $nextPreserveKey;
	} // getNextPreserveKeyAndPurgeOld
	
	protected function getPreserveKeySessionKey($preserveKey) {
		return "__fw" . $preserveKey;
	} // getPreserveKeySessionKey
	
	protected function getSection($action) {
		return array_shift(explode('.', $this->getSectionAndItem($action), 2));
	} // getSection
	
	public function getSectionAndItem($action = '') {
		if (strlen($action) === 0) {
			return $this->framework->home;
		}
		$parts = explode('.', $action);
		if (count($parts) === 1) {
			return $this->framework->defaultSection . '.' . $action; 
		} else if (strlen($parts[0]) === 0) {
			return $this->framework->defaultSection . $action;
		}
		return $parts[0] . '.' . $parts[1];
	} // getSectionAndItem
	
	protected function getService($section) {
		return $this->getCachedObject('service', $section);
	} // getService
	
	public function getServiceKey($action) {
		return 'data';
	} // getServiceKey

	protected function internalLayout($layoutPath, $body) {
		$rc = $this->context;
		$fw = $this;
		if (!$this->request->exists('controllerExecutionComplete')) {
			throw new \Exception('Invalid to call the layout method at this point.');
		}
		ob_start();
		require "$layoutPath";
		return ob_get_clean();
	} // internalLayout
	
	protected function internalView($viewPath, $args = array()) {
		$rc = $this->context;
		$fw = $this;
		if (!$this->request->exists('controllerExecutionComplete')) {
			throw new \Exception('Invalid to call the view method at this point.');
		}
		ob_start();
		require "$viewPath";
		return ob_get_clean();
	} // internalView

	public function layout($path, $body) {
		return $this->internalLayout($this->parseViewOrLayoutPath($path, 'layout'), $body);
	} // layout
	
	public function onError($ex) {
		$this->failure($ex);
	} // onError
	
	public function onMissingView($rc) {
		$this->viewNotFound();
	} // onMissingView
	
	public function onRequest($targetPath) {
		$once = array();
		$this->request->controllerExecutionStarted = TRUE;
		if ($this->request->exists('controllers')) {
			foreach ($this->request->controllers as $tuple) {
				if (!array_key_exists($tuple['key'], $once)) {
					$once[$tuple['key']] = 0;
					$this->doController($tuple['controller'], 'before');
				}
				$this->doController($tuple['controller'], 'start' . $tuple['item']);
				$this->doController($tuple['controller'], $tuple['item']);
				$once[$tuple['key']]++;
			}
		}
		foreach ($this->request->services as $tuple) {
			$result = $this->doService($tuple['service'], $tuple['item'], $tuple['args'], $tuple['enforceExistence']);
			if ($tuple['key'] !== '') {
				$this->context->{$tuple['key']} = $result;
			}
		}
		$this->request->serviceExecutionComplete = TRUE;
		if ($this->request->exists('controllers')) {
			foreach ($this->request->controllers as $tuple) {
				$this->doController($tuple['controller'], 'end' . $tuple['item']);
				if (!array_key_exists($tuple['key'], $once)) {
					$once[$tuple['key']] = -1;
				}
				$once[$tuple['key']]--;
				if ($once[$tuple['key']] === 0) {
					$this->doController($tuple['controller'], 'after');
				}
			}
		}
		$this->request->controllerExecutionComplete = TRUE;
		$this->buildViewAndLayoutQueue();
		if ($this->request->exists('view')) {
			$out = $this->internalView($this->request->view);
		} else {
			$out = $this->onMissingView($this->context);
		}
		foreach ($this->request->layouts as $layout) {
			if ($this->request->exists('layout') && !$this->request->layout) {
				break;
			}
			$out = $this->internalLayout($layout, $out);
		}
		print $out;
	} // onRequest
	
	public function onRequestStart($targetPath) {
		$pathInfo = $this->cgiPathInfo;
		$sesIx = 0;
		$sesN = 0;
		$this->setupRequestDefaults();
		$this->setupApplicationWrapper();
		if ((strlen($pathInfo) > strlen($this->cgiScriptName)) && (substr($pathInfo, 0, strlen($this->cgiScriptName)) === $this->cgiScriptName)) {
			// path contains the script
			$pathInfo = substr($pathInfo, strlen($this->cgiScriptName));
		} else if ((strlen($pathInfo) > 0) && ($pathInfo === substr($this->cgiScriptName, 0, strlen($pathInfo)))) {
			// path is the same as the script
			$pathInfo = '';
		}
		if (substr($pathInfo, 0, 1) === '/') {
			$pathInfo = substr($pathInfo, 1);
		}
		$pathInfo = explode('/', $pathInfo);
		$sesN =count($pathInfo);
		for ($sesIx = 0; $sesIx < $sesN; $sesIx++) {
			if ($sesIx === 0) {
				$this->context->{$this->framework->action} = $pathInfo[$sesIx];
			} else if ($sesIx === 1) {
				$this->context->{$this->framework->action} = $pathInfo[$sesIx-1] . '.' . $pathInfo[$sesIx];
			} else if (($sesIx % 2) === 0) {
				$this->context->{$pathInfo[$sesIx]} = '';
			} else {
				$this->context->{$pathInfo[$sesIx-1]} = $pathInfo[$sesIx];
			}
		} // for each ses index
		foreach ($_REQUEST as $key => $val) {
			$this->context->{$key} = $val;
		}
		if (!$this->context->exists($this->framework->action)) {
			$this->context->{$this->framework->action} = $this->framework->home;
		} else {
			$this->context->{$this->framework->action} = $this->getSectionAndItem($this->context->{$this->framework->action});
		}
		$this->request->{$this->framework->action} = self::validateAction(strtolower($this->context->{$this->framework->action}));
		$this->setupRequestWrapper(TRUE);
	} // onRequestStart
	
	protected function parseViewOrLayoutPath($path, $type) {
		$pathInfo = array(
			'path' => $path,
			'base' => $this->request->base,
		);
		return $this->customizeViewOrLayoutPath($pathInfo, $type, "${pathInfo['base']}${type}s/${pathInfo['path']}.php");
	} // parseViewOrLayoutPath
	
	public function redirect($action, $preserve = 'none', $append = 'none', $path = NULL, $queryString = '') {
		$baseQueryString = array();
		$key = '';
		$val = '';
		$keys = '';
		$preserveKey = '';
		$targetUrl = '';
		if ($append !== 'none') {
			if ($append === 'all') {
				$keys = array_keys($this->context);
			} else {
				$keys = explode(',', $append);
			}
			foreach ($keys as $key) {
				if (array_key_exists($key, $this->context) && is_scalar($this->context[$key])) {
					$baseQueryString[] = $key . '=' . urlencode($this->context[$key]);
				}
			}
		}
		$baseQueryString = implode('&', $baseQueryString);
		if ($baseQueryString !== '') {
			if ($queryString !== '') {
				if ((substr_compare($queryString, '?', 0) === 0) || (substr_compare($queryString, '#', 0) === 0)) {
					$baseQueryString .= $queryString;
				} else {
					$baseQueryString .= '&' . $queryString;
				}
			}
		} else {
			$baseQueryString = $queryString;
		}
		$targetUrl = $this->buildUrl($action, $path, $baseQueryString);
		if ($preserveKey !== '') {
			if (strpos($targetUrl, '?') !== FALSE) {
				$preserveKey = '&' . $this->framework->preserveKeyURLKey . '=' . $preserveKey;
			} else {
				$preserveKey = '?' . $this->framework->preserveKeyURLKey . '=' . $preserveKey;
			}
			$targetUrl .= $preserveKey;
		}
		header('Location: ' . $targetUrl);
		exit;
	} // redirect
	
	public function service($action, $key, $args = array(), $enforceExistence = TRUE) {
		$section = $this->getSection($action);
		$item = $this->getItem($action);
		if ($this->request->exists('serviceExecutionComplete')) {
			throw new \Exception("Service '$action' may not be added at this point.");
		}
		$tuple = array(
			'service' => $this->getService($section),
			'item'    => $item,
			'key'     => $key,
			'args'    => $args,
			'enforceExistence' => $enforceExistence
		);
		if (is_object($tuple['service'])) {
			$services = $this->request->services;
			array_push($services, $tuple); 
			$this->request->services = $services;
		} else if ($enforceExistence) {
			throw new \Exception("Service '$action' does not exist");
		}
	} // service
	
	public function setupApplication() {}
	
	protected function setupApplicationWrapper() {
		$this->cache->lastReload = time();
		$this->cache->fileExists = array();
		$this->cache->controllers = array();
		$this->cache->services = array();
		$this->setupApplication();
	} // setupApplicationWrapper
	
	protected function setupFrameworkDefaults($settings) {
		$defaults = array(
			'action'         => 'action',
			'defaultSection' => 'main',
			'defaultItem'    => 'home',
			'generateSES'    => FALSE,
			'SESOmitIndex'   => FALSE,
			'base'           => $this->appRoot,
			'baseUrl'        => 'useCgiScriptName',
			'cacheFileExists' => TRUE,
			'suppressImplicitService' => FALSE,
			'maxNumContextsPreserved' => 10,
			'preserveKeyURLKey' => 'fwpk'
		);
		foreach ($defaults as $key => $val) {
			$this->framework->param($key, array_key_exists($key, $settings) ? $settings[$key] : $val);
		}
		$this->framework->param('home', $this->framework->defaultSection . '.' . $this->framework->defaultItem);
	} // setupFrameworkDefaults
	
	public function setupRequest() {}
	
	protected function setupRequestDefaults() {
		$this->request->base = $this->framework->base;
	} // setupRequestDefaults
	
	protected function setupRequestWrapper($runSetup = FALSE) {
		$this->request->section  = $this->getSection($this->request->action);
		$this->request->item     = $this->getItem($this->request->action);
		$this->request->services = array();
		if ($runSetup) {
			$this->setupRequest();
		}
		$this->controller($this->request->action);
		if (!$this->framework->suppressImplicitService) {
			$this->service($this->request->action, $this->getServiceKey($this->request->action), array(), FALSE);
		}
	} // setupRequestWrapper
	
	public function setView($action) {
		$this->request->overrideViewAction = $this->validateAction($action);
	} // setView
	
	protected static function validateAction($action) {
		if ((strpos($action, '/') !== FALSE) || (strpos($action, '\\') !== FALSE)) {
			throw new \Exception('Actions cannot contain slashes');
		}
		return $action;
	} // validateAction
	
	public function view($path, $args = NULL) {
		return $this->internalView($this->parseViewOrLayoutPath($path, 'view'), $args);
	} // view
	
	protected function viewNotFound() {
		throw new \Exception("Unable to find a view for '" . $this->request->action . "' action.");
	} // viewNotFound
}