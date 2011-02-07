<?php
namespace Org\Corfield;

/**
 * This is a helper class to work around some pass-by-reference issues
 * with __call in some versions of PHP 5.3.
 * It sucks, and needs to go away.
 * @author Rick Osborne
 */
class FW1Obj {
	private $properties = array();

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
		elseif ($property === 'pathInfo')
			return $this->cgiPathInfo;
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
			// echo "Method '$method' is not available for controller '" . get_class($obj) . "'.";
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
	
	/**
	 * cfdump-style debugging output
	 * @param $var    The variable to output.
	 * @param $limit  Maximum recursion depth for arrays (default 0 = all)
	 * @param $label  text to display in complex data type header
	 * @param $depth  Current depth (default 0)
	 */
	public function dump(&$var, $limit = 0, $label = '', $depth = 0) {
		if (($limit > 0) && ($depth >= $limit))
			return;
		static $seen = array();
		$he = function ($s) { return htmlentities($s); };
		$self = $this;
		$echoFunction = function($var, $tabs, $label = '') use ($self) {
			if (!is_subclass_of($var, 'ReflectionFunctionAbstract')) {
				$var = new \ReflectionFunction($var);
			}
			echo "$tabs<table class=\"dump function\">$tabs<thead><tr><th>" . ($label != '' ? $label . ' - ' : '') . (is_callable(array($var, 'getModifiers')) ? htmlentities(implode(' ', \Reflection::getModifierNames($var->getModifiers()))) : '') . " function " . htmlentities($var->getName()) . "</th></tr></thead>$tabs<tbody>";
			echo "$tabs<tr><td class=\"value\">$tabs<table class=\"dump layout\">$tabs<tr><th>Parameters:</th><td>";
			$params = $var->getParameters();
			if (count($params) > 0) {
				echo "</td></tr>$tabs<tr><td colspan=\"2\">$tabs<table class=\"dump param\">$tabs<thead><tr><th>Name</th><th>Array/Ref</th><th>Required</th><th>Default</th></tr></thead>$tabs<tbody>";
				foreach ($params as $param) {
					echo "$tabs<tr><td>" . htmlentities($param->getName()) . "</td><td>" . ($param->isArray() ? "Array " : "") . ($param->isPassedByReference() ? "Reference" : "") . "</td><td>" . ($param->isOptional() ? "Optional" : "Required") . "</td><td>";
					if ($param->isOptional()) {
						$self->dump($param->getDefaultValue());
					}
					echo "</td></tr>";
				}
				echo "$tabs</tbody>$tabs</table>";
			} else {
				echo "none</td></tr>";
			}
			$comment = trim($var->getDocComment());
			if (($comment !== NULL) && ($comment !== '')) {
				echo "$tabs<tr><th>Doc Comment:</th><td><kbd>" . str_replace("\n", "<br/>", htmlentities($comment)) . "</kbd></td></tr>";
			}
			echo "</table>$tabs</td></tr>";
			echo "$tabs</tbody>$tabs</table>";
		};
		$tabs = "\n" . str_repeat("\t", $depth);
		$depth++;
		$printCount = 0;
		if (!array_key_exists('fw1dumpstarted', $_REQUEST)) {
			$_REQUEST['fw1dumpstarted'] = TRUE;
			echo<<<DUMPCSS
<style type="text/css">/* fw/1 dump */
table.dump { color: black; background-color: white; font-size: xx-small; font-family: verdana,arial,helvetica,sans-serif; border-spacing: 0; border-collapse: collapse; }
table.dump th { text-indent: -2em; padding: 0.25em 0.25em 0.25em 2.25em; color: #fff; }
table.dump td { padding: 0.25em; }
table.dump th, table.dump td { border-width: 2px; border-style: solid; border-spacing: 0; vertical-align: top; text-align: left; }
table.dump.object, table.dump.object td, table.dump.object th { border-color: #f00; }
table.dump.object th { background-color: #f44; }
table.dump.object .key { background-color: #fcc; }
table.dump.array, table.dump.array td, table.dump.array th { border-color: #060; }
table.dump.array th { background-color: #090; }
table.dump.array .key { background-color: #cfc; }
table.dump.struct, table.dump.struct td, table.dump.struct th { border-color: #00c; }
table.dump.struct th { background-color: #44c; }
table.dump.struct .key { background-color: #cdf; }
table.dump.function, table.dump.function td, table.dump.function th { border-color: #a40; }
table.dump.function th { background-color: #c60; }
table.dump.layout, table.dump.layout td, table.dump.layout th { border-color: #fff; }
table.dump.layout th { font-style: italic; background-color: #fff; color: #000; font-weight: normal; }
table.dump.param, table.dump.param td, table.dump.param th { border-color: #ddd; }
table.dump.param th { background-color: #eee; color: black; font-weight: bold; }
</style>
DUMPCSS;
		}
		if (is_array($var)) {
			$label = $label === '' ? (($var === $_POST) ? '$_POST' : (($var === $_GET) ? '$_GET' : (($var === $_COOKIE) ? '$_COOKIE' : (($var === $_ENV) ? '$_ENV' : (($var === $_FILES) ? '$_FILES' : (($var === $_REQUEST) ? '$_REQUEST' : (($var === $_SERVER) ? '$_SERVER' : (($var === $_SESSION) ? '$_SESSION' : '')))))))) : $label;      
			$c = count($var);
			if(isset($var['fw1recursionsentinel'])) {
				echo "(Recursion)";
			}
			$aclass = (($c > 0) && array_key_exists(0, $var) && array_key_exists($c - 1, $var)) ? 'array' : 'struct';
			$var['fw1recursionsentinel'] = true;
			echo "$tabs<table class=\"dump ${aclass}\">$tabs<thead><tr><th colspan=\"2\">" . ($label != '' ? $label . ' - ' : '') . "array" . ($c > 0 ? "" : " [empty]") . "</th></tr></thead>$tabs<tbody>";
			foreach ($var as $index => $aval) {
				if ($index === 'fw1recursionsentinel')
					continue;
				echo "$tabs<tr><td class=\"key\">" . $he($index) . "</td><td class=\"value\">";
				$this->dump($aval, $limit, '', $depth);
				echo "</td></tr>";
				$printCount++;
				if (($limit > 0) && ($printCount >= $limit) && ($aclass === 'array'))
					break;
			}
			echo "$tabs</tbody>$tabs</table>";
			// unset($var['fw1recursionsentinel']);
		} elseif (is_string($var)) {
			echo $var === '' ? '[EMPTY STRING]' : htmlentities($var);
		} elseif (is_bool($var)) {
			echo $var ? "TRUE" : "FALSE";
		} elseif (is_callable($var) || (is_object($var) && is_subclass_of($var, 'ReflectionFunctionAbstract'))) {
			$echoFunction($var, $tabs, $label);
		} elseif (is_float($var)) {
			echo "(float) " . htmlentities($var);
		} elseif (is_int($var)) {
			echo "(int) " . htmlentities($var);
		} elseif (is_null($var)) {
			echo "NULL";
		} elseif (is_object($var)) {
			$ref = new \ReflectionObject($var);
			$parent = $ref->getParentClass();
			$interfaces = implode("<br/>implements ", $ref->getInterfaceNames());
			try {
				$serial = serialize($var);
			} catch (\Exception $e) {
				$serial = 'hasclosure' . $ref->getName();
			}
			$objHash = 'o' . md5($serial);
			$refHash = 'r' . md5($ref);
			echo "$tabs<table class=\"dump object\"" . (isset($seen[$refHash]) ? "" : "id=\"$refHash\"") . ">$tabs<thead>$tabs<tr><th colspan=\"2\">" . ($label != '' ? $label . ' - ' : '') . "object " . htmlentities($ref->getName()) . ($parent ? "<br/>extends " .$parent->getName() : "") . ($interfaces !== '' ? "<br/>implements " . $interfaces : "") . "</th></tr>$tabs<tbody>";
			if (isset($seen[$objHash])) {
				echo "$tabs<tr><td colspan=\"2\"><a href=\"#$refHash\">[see above for details]</a></td></tr>";
			} else {
				$seen[$objHash] = TRUE;
				$constants = $ref->getConstants();
				if (count($constants) > 0) {
					echo "$tabs<tr><td class=\"key\">CONSTANTS</td><td class=\"values\">$tabs<table class=\"dump object\">";
					foreach ($constants as $constant => $cval) {
						echo "$tabs<tr><td class=\"key\">" . htmlentities($constant) . "</td><td class=\"value constant\">";
						$this->dump($cval, $limit, '', $depth);
						echo "</td></tr>";
					}
					echo "$tabs</table>$tabs</td></tr>";
				}
				$properties = $ref->getProperties();
				if (count($properties) > 0) {
					echo "$tabs<tr><td class=\"key\">PROPERTIES</td><td class=\"values\">$tabs<table class=\"dump object\">";
					foreach ($properties as $property) {
						echo "$tabs<tr><td class=\"key\">" . htmlentities(implode(' ', \Reflection::getModifierNames($property->getModifiers()))) . " " . $he($property->getName()) . "</td><td class=\"value property\">";
						$wasHidden = $property->isPrivate() || $property->isProtected();
						$property->setAccessible(TRUE);
						$this->dump($property->getValue($var), $limit, '', $depth);
						if ($wasHidden) { $property->setAccessible(FALSE); }
						echo "</td></tr>";
					}
					echo "$tabs</table>$tabs</td></tr>";
				}
				$methods = $ref->getMethods();
				if (count($methods) > 0) {
					echo "$tabs<tr><td class=\"key\">METHODS</td><td class=\"values\">";
					if (isset($seen[$refHash])) {
						echo "<a href=\"#$refHash\">[see above for details]</a>";
					} else {
						$seen[$refHash] = TRUE;
						echo "$tabs<table class=\"dump object\">";
						foreach ($methods as $method) {
							echo "$tabs<tr><td class=\"key\">" . htmlentities($method->getName()) . "</td><td class=\"value function\">";
							$echoFunction($method, $tabs, '');
							echo "</td></tr>";
						}
						echo "$tabs</table>";
					}
					echo "$tabs</td></tr>";
				}
			}
			echo "$tabs</tbody>$tabs</table>";
		} elseif (is_resource($var)) {
			echo "(Resource)";
		} elseif (is_numeric($var)) {
			echo  htmlentities($var);
		} elseif (is_scalar($var)) {
			echo htmlentities($var);
		} else {
			echo gettype($var);
		}
	} // dump
	
	protected function failure($ex) {
		echo "<h1>Error</h1>";
		if ($this->request->exists('failedAction')) {
			$fa = $this->request->failedAction;
			echo "<p>The action $fa failed.</p>";
		}
		echo "<p>" . htmlentities($ex->getMessage()) . "</p>";
		// echo $this->dump($ex);
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
		echo $out;
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