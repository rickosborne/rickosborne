<?php
require_once('../Framework.php');

class ExampleApp extends \Org\Corfield\Framework1 {
	
	public function getServiceKey($action) {
		// by default, the service call goes into 'data'
		// override this to put results into the item/method name 
		return $this->getItem($action);
	} // getServiceKey
	
}