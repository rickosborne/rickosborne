<?php
namespace Services;

class main {
	
	public function reverse($name = NULL) {
		if ($name !== NULL)
			return strrev($name);
		return NULL;
	}
	
	public function time() {
		return time();
	}
	
}