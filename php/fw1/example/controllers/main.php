<?php
namespace Controllers;

class main {
	
	protected $fw;
	
	public function __construct($fw) {
		$this->fw = $fw;
	}
	
	public function __call($method, $args) {
		// this is like ColdFusion's onMissingMethod
		$rc = $args[0];
		$rc->{$method} = 'missing';
	}
	
	public function startReverse(&$rc) {
		$rc->param('name', 'no name given');
		// note that PHP does not have named function arguments
		// your service() calls will need to include the args in the correct order
		$this->fw->service('reverse', 'reverse', array($rc->name));
	}
	
	public function endTime(&$rc) {
		$rc->param('time', 'Something went wrong');
	}
	
}