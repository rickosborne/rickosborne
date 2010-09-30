/**
 * @author rosborne
 */
(function(){
	var decorateForms = function(){
		var hasClass = function(e, c){
			return e.className.match(new RegExp('(\\s|^)' + c + '(\\s|$)'));
		};
		var addClass = function(e, c){
			if (!hasClass(e, c)) 
				e.className += ' ' + c;
		};
		var removeClass = function(e, c){
			if (hasClass(e, c)) 
				e.className = e.className.replace(new RegExp('(\\s|^)' + c + '(\\s|$)'), ' ');
		};
		for (var fi = 0; fi < document.forms.length; fi++) {
			var f = document.forms[fi];
			for (var n = 0; n < f.elements.length; n++) {
				var e = f.elements[n];
				var p = e.getAttribute("placeholder");
				var v = e.value;
				if (p) {
					if (v === '') {
						e.value = p;
						addClass(e, 'placeholder');
					}
					e.onfocus = function(evt){
						var e = evt.target;
						if (e.value === e.getAttribute("placeholder")) 
							e.value = '';
					};
					e.onblur = function(evt){
						var e = evt.target;
						if (e.value === '') {
							e.value = e.getAttribute("placeholder");
							addClass(e, 'placeholder');
						}
						else 
							removeClass(e, 'placeholder');
					}
				} // if placeholder
				var t5 = e.getAttribute("type5");
				if (t5) {
					var e5 = document.createElement("input");
					e5.setAttribute("type", t5);
					if (e5.type === t5) {
						e.setAttribute("type", t5);
					}
				} // html5 type
			} // for n
			var onsubmit = function(evt){
				var f = evt.target;
				for (var n = 0; n < f.elements.length; n++) {
					var e = f.elements[n];
					var p = e.getAttribute("placeholder");
					var t = e.getAttribute("title");
					if (p && t && (e.value === p)) {
						alert("Please provide your " + t);
						e.focus();
						evt.preventDefault();
						return false;
					}
				}
				var p1 = f.elements['password1'];
				var p2 = f.elements['password2'];
				if (p1 && p2 && (p1.value !== p2.value)) {
					alert("Please ensure your passwords match.");
					p1.value = '';
					p2.value = '';
					p1.focus();
					evt.preventDefault();
					return false;
				}
				return true;
			} // onclick
			if (f.addEventListener) 
				f.addEventListener('submit', onsubmit, false);
			else 
				f.attachEvent('onsubmit', onsubmit);
		} // for form
	}; // decorateForms
	if (document.addEventListener)
		document.addEventListener("DOMContentLoaded", decorateForms, false);
	else if (document.all && !window.opera) {
		document.write('<script type="text/javascript" id="contentloadtag" defer="defer" src="javascript:void(0)"><\/script>');
		document.getElementById("contentloadtag").onreadystatechange = function(){
			if (this.readyState == "complete"){
				alreadyrunflag = 1;
				decorateForms();
			}
		};
	} // else if IE
	else if (/Safari/i.test(navigator.userAgent)) {
		var _timer = setInterval(function(){
		if(/loaded|complete/.test(document.readyState)){
			clearInterval(_timer);
			decorateForms();
		}}, 10);
	}
})();