#
# Varnish file by Steffen Kroggel (developer@steffenkroggel.de)
# Version 1.0.8
# Date 2020/11/18
#

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;
import std;
import xkey;

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "127.0.0.1";
    .port = "8080";

    # How long to wait for a backend connection? (default: 3.5s)
    .connect_timeout = 3.5s;

    # How long to wait before we receive a first byte from our backend? (default: 60s)
    .first_byte_timeout = 120s;

    # How long to wait between bytes received from our backend? (default: 60s)
    .between_bytes_timeout  = 120s;
}

backend default_ssl{
    .host = "127.0.0.1";
    .port = "8443";

    # How long to wait for a backend connection? (default: 3.5s)
    .connect_timeout = 3.5s;

    # How long to wait before we receive a first byte from our backend? (default: 60s)
    .first_byte_timeout = 120s;

    # How long to wait between bytes received from our backend? (default: 60s)
    .between_bytes_timeout  = 120s;
}

# define IPs that are allowed to ban / purge
# Can not be used behind a proxy
# acl purgers {
#   "127.0.0.1";
#}

#=======================================================
# Sub-routine for hash-generation for cached objects
#=======================================================
sub vcl_hash {
    
    # In the default setup the cache-key is calculated based 
    # on the content of the Host header or the IP address of the server and the URL
    hash_data(req.url);
    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }

    # Add ssl-prefix here if set
    # This way we can cache different content for SSL and non-SSL
    # This is important e.g. for forced redirects to SSL
    if (std.port(server.ip) == 9443) {
	hash_data("ssl");
    }

    return (lookup);
}


#========================================================
# Sub-routine when request is received
#========================================================
sub vcl_recv {
    # Happens before we check if we have this in cache already.
    #
    # Typically you clean up the request here, removing cookies you don't need,
    # rewriting the request, etc.

    # Set the right backend according to used port
    if (std.port(server.ip) == 9443) {
	set req.backend_hint = default_ssl;
    } else {
	set req.backend_hint = default;
    }


    # Set X-Forwarded-For Header
    if (req.restarts == 0) {

        if (req.http.X-Forwarded-For) {
            set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }

    # Catch BAN Command for TYPO3 extension "Varnish"
    # This bans specific cache objects from cache
    if (
        (req.method == "BAN")
        || (req.method == "PURGE")    
    ) {

        # Check if  IP is allowed to BAN/Purge
        if (req.http.X-Forwarded-For ~ "^127.0.0.0") {
            return(synth(405,"Not allowed. IP: " + req.http.X-Forwarded-For));
            #===
        }
        
        # Check if one single page of an instance is to be invalidated
	if (req.http.Varnish-Ban-TYPO3-Pid && req.http.Varnish-Ban-TYPO3-Sitename) {
	    set req.http.n-gone = xkey.softpurge(req.http.Varnish-Ban-TYPO3-Sitename + "_" + req.http.Varnish-Ban-TYPO3-Pid);
	    return (synth(200, "Softpurge. Invalidated " + req.http.n-gone + " objects with " + req.http.Varnish-Ban-TYPO3-Sitename + "_" + req.http.Varnish-Ban-TYPO3-Pid));
            #====

        # Check if all pages of an instance are to be invalidated
	} else if (req.http.Varnish-Ban-TYPO3-Sitename) {
	    set req.http.n-gone = xkey.softpurge(req.http.Varnish-Ban-TYPO3-Sitename);
            return (synth(200, "Softpurge. Invalidated " + req.http.n-gone + " objects with " + req.http.Varnish-Ban-TYPO3-Sitename));
            #===

        # Fallback with minimum impact
        } else {
	    ban("req.http.host == " + req.http.host + " && req.url == " + req.url);
            return(synth(200,"Ban. Banned " + req.http.host + req.url));
            #===
        }
    }

# ONLY FOR DEVELOPMENT
return (pass);

    # Only activate varnish for certain domains
    if (
        (! req.http.host ~ "^(www\.|static([0-9]+)\.)?aprodi-projekt\.de$")
        # && (! req.http.host ~ "^(www\.|static([0-9]+)\.)?azubimarketing\.works$")
        # && (! req.http.host ~ "^(www\.|static([0-9]+)\.)?digitalisierungs-cockpit\.de$")
        && (! req.http.host ~ "^(www\.|static([0-9]+)\.)?eepa-deutschland\.de$")
        && (! req.http.host ~ "^(www\.|static([0-9]+)\.)?rkw\.de$")
        && (! req.http.host ~ "^(www\.|static([0-9]+)\.)?rkw-bw\.de$")
        && (! req.http.host ~ "^(www\.|static([0-9]+)\.)?rkw-bremen\.de$")
        && (! req.http.host ~ "^(www\.|static([0-9]+)\.)?rkw-kompetenzzentrum\.de$")
        && (! req.http.host ~ "^(www\.|static([0-9]+)\.)?rkw-thueringen\.de$")

        && (! req.http.host ~ "^(www\.)?baumitbim\.de$")
        && (! req.http.host ~ "^(www\.)?bst\.events$")
        && (! req.http.host ~ "checks\.rkw-azubimarketing\.de$")
        && (! req.http.host ~ "^(www\.)?digiscouts\.de$")
        && (! req.http.host ~ "^(www\.)?eanpc\.eu$")
        && (! req.http.host ~ "^(www\.)?frauenambau\.de$")
        && (! req.http.host ~ "^geschichte\.rkw\.de$")
        && (! req.http.host ~ "^(www\.)?karriereseiten-check\.de$")
        && (! req.http.host ~ "^(www\.)?perso-net\.de$")
        && (! req.http.host ~ "^(www\.)?ressinnobau\.de$")
        && (! req.http.host ~ "^(www\.)?rkw-sachsenanhalt\.de$")

        # && (! req.http.host ~ "^mein\.rkw\.de$")

    ) {
#        return (pass);
        #===
    }


    # Pipe unknown Methods - means: Varnish only passed through without caching
    if (
	req.method != "GET" &&
	req.method != "HEAD" &&
	req.method != "PUT" &&
	req.method != "POST" &&
	req.method != "TRACE" &&
	req.method != "OPTIONS" &&
	req.method != "DELETE"
    ) {
	return (pipe);
	#===
    }

    # Cache only GET or HEAD Requests
    if (req.method != "GET" && req.method != "HEAD") {
	return (pass);
	#===
    }

    # Do not cache authorized content (login via htaccess)
    if (req.http.Authorization) {
	return (pass);
	#===
    }

    # Force lookup if the request is a no-cache request from the client (STRG + F5)
    if (req.http.Cache-Control ~ "no-cache") {
        return (pass);
        #=== 
    }

    # Do not cache image files, pdfs, xls, docs, zips, etc. This fills up the cache to fast
    # and it keeps WebP-optimization on apache side from working
    if (req.url ~ "(?i)\.(jpeg|jpg|png|gif|ico|webp|txt|pdf|gz|zip|doc|docx|ppt|pptx|xls|xlsx)$") {
        return (pass);
	    #===
    } 

    # Do not cache TYPO3 BE User requests
    if (req.http.Cookie ~ "be_typo_user" || req.url ~ "^/typo3/") {
        return (pass);
        #===
    }

    # Do not cache non-cached pages or specific page types and params
    # We also ignore some RealUrl-coded params from extensions
    if (
	(req.url ~ "^/nc/?")
	|| (req.url ~ "$/gitpull.php")
	|| (req.url ~ "(\?|&)type=")
	|| (req.url ~ "(\?|&)typeNum=")
	|| (req.url ~ "(\?|&)no_cache=1")
	|| (req.url ~ "(\?|&)no_varnish=1")
	|| (req.url ~ "(\?|&)eID=")
	|| (req.url ~ "(\?|&)cHash=")
	|| (req.url ~ "/tx-[a-z-]+/")
	|| (req.url ~ "/pagetype-[a-z-]+/")
	|| (req.url ~ "^/phpmyadmin/?")
    ) {
	return (pass);
	#===
    }

    # unset grace-header from request
    unset req.http.grace;

    # Removes all cookies named __utm? (utma, utmb...) and __unam - tracking thing
    # Otherwise we might run into problems with caching
    set req.http.Cookie = regsuball(req.http.Cookie, "(^|(?<=; )) *__utm.=[^;]+;? *", "\1"); # Google Analytics
    set req.http.Cookie = regsuball(req.http.Cookie, "(^|(?<=; )) *__unam=[^;]+;? *", "\1"); # Google Analytics
    set req.http.Cookie = regsuball(req.http.Cookie, "(^|(?<=; )) *_et_coid=[^;]+;? *", "\1"); # eTracker
    set req.http.Cookie = regsuball(req.http.Cookie, "(^|(?<=; )) *isSdEnabled=[^;]+;? *", "\1"); # perso-net shit
    set req.http.Cookie = regsuball(req.http.Cookie, "(^|(?<=; )) *cookie_optin=[^;]+;? *", "\1"); # Cookie-Opt-In
    if (req.http.Cookie == "") {
        unset req.http.Cookie;
    }

    # normalize Accept-Encoding to reduce vary
    if (req.http.Accept-Encoding) {
	if (req.http.User-Agent ~ "MSIE 6") {
	    unset req.http.Accept-Encoding;
	} elsif (req.http.Accept-Encoding ~ "gzip") {
	    set req.http.Accept-Encoding = "gzip";
	} elsif (req.http.Accept-Encoding ~ "deflate") {
	    set req.http.Accept-Encoding = "deflate";
	} else {
	    unset req.http.Accept-Encoding;
	}
    } 

    # Do NOT gzip JS and CSS-files because otherwise they won't be cached!
    # Varnish will set gzip itself! 
    # and it keeps WebP-optimization on apache side from working
    if (req.url ~ "(?i)\.(css|js)$") {
        unset req.http.Accept-Encoding;
    }

    # normalize Accept-Language (e.g en-uk, en-us --> en)
    if (req.http.Accept-Language ~ "en") {
        set req.http.Accept-Language = "en";
    } elsif (req.http.Accept-Language ~ "de") {
        set req.http.Accept-Language = "de";
    } elsif (req.http.Accept-Language ~ "fr") {
        set req.http.Accept-Language = "fr";
    } else {
        # unknown language. Remove the accept-language header and
        # use the backend default.
        unset req.http.Accept-Language;
    }

    # Prevent default varnish configuration from beeing executed
    return (hash);
    #===
}

#========================================================
# Sub-routine after data from backend is received and before it is cached
#========================================================
sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    #
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does.

    # Set TTL and grace
    set beresp.ttl = 1w;
    set beresp.grace = 3d;

    # Set reduced TTL for home
    if (bereq.url ~ "^/$") {
         set beresp.ttl = 6h;
    }

    # Handle gzip-Compression in varnish!
    # We only do this for files were compression is really usefull (e.g. not for already compressed image files)
    if (bereq.http.Accept-Encoding == "gzip") {
        if (
	    beresp.http.content-type ~ "text/plain"
            || beresp.http.content-type ~ "text/xml"
            || beresp.http.content-type ~ "text/css"
            || beresp.http.content-type ~ "text/html"
            || beresp.http.content-type ~ "application/(x-)?javascript"
            || beresp.http.content-type ~ "application/(x-)?font-ttf"
            || beresp.http.content-type ~ "application/(x-)?font-opentype"
            || beresp.http.content-type ~ "application/font-woff"
            || beresp.http.content-type ~ "application/vnd\.ms-fontobject"
            || beresp.http.content-type ~ "image/svg\+xml"
       ) {
	    set beresp.do_gzip = true;
	}
    }

    # Cache only GET or HEAD Requests and keep that descision for the next 2 minutes
    if (
	(bereq.method != "GET")
	&& (bereq.method != "HEAD")
    ) {
	set beresp.ttl = 120s;
        set beresp.grace = 0s;
	set beresp.uncacheable = true;
	return (deliver);
	#===
    }

    # Do not cache error pages and redirects and keep decision for the next 2 minutes
    if (beresp.status >= 300) {

        set beresp.ttl = 120s;
        set beresp.grace = 0s;

        # For redirects (301,302) and page not found (404) we have another ttl
        # and we DO cache them to have a better hit rate
        if (
            (beresp.status == 301)
            || (beresp.status == 302)
            || (beresp.status == 404)
        ) {
            set beresp.ttl = 1d;
        } else {
            set beresp.uncacheable = true;
        }

        return (deliver);
        #===
    }


    # Only cache objects that are requested with frontend-cookies if ProxyCaching is set to 1
    if (
        (bereq.http.Cookie)
        && (! beresp.http.X-TYPO3-ProxyCaching == "1")
    ) {

        # Do not cache this object and do not keep decision 
        set beresp.uncacheable = true;
        set beresp.ttl = 0s;
        set beresp.grace = 0s;
        return (deliver);
    }


    # Check for some things in the response-header that indicate that we should not cache
    # e.g. we do NOT cache contents that are about to set a cookie
    # or where ProxyCaching is set to 2
    if (
        (beresp.http.Set-Cookie)
        || (beresp.http.Vary == "*")
        || (beresp.http.Authorization)
        || (beresp.http.Pragma ~ "nocache")
        || (beresp.http.Cache-Control ~ "no-cache")
        || (beresp.http.X-TYPO3-ProxyCaching == "2")

        # TYPO3 uses "private" when INT-Scripts are used!
        # so we check for ProxyCaching variable in addition
        || (
            (beresp.http.Cache-Control ~ "private")
            && (! beresp.http.X-TYPO3-ProxyCaching == "1")
        )
     ) {

        # Do not cache this object and do not keep the decision
        set beresp.uncacheable = true;
        set beresp.ttl = 0s;
        set beresp.grace = 0s;
        return (deliver);
        #===
    }

    return (deliver);
    #===

}

#========================================================
# Sub-routine after object is loaded from cache
#========================================================
sub vcl_hit {

    # If backend is not if healthy we deliver the cached object no matter what
    if (! std.healthy(req.backend_hint)) {
        return (deliver);
        #===
    }

    # Based on the already cached object we check if there is login sensitive data allowed on the cached pages
    # If so, we pass to backend if a cookie is set
    if (
	(! obj.http.X-TYPO3-ProxyCaching == "1")
	&& (req.http.Cookie)
    ){
	return (pass);
	#===
    }

    # Object in cache is still valid - deliver it
    if (obj.ttl >= 0s) {
	return (deliver);
	#===
    }

    # We have no fresh fish. Lets take the stale ones.
    if (obj.ttl + obj.grace > 0s) {
	return (deliver);
        #===
    }

    # Object in cache is invalid - fetch & deliver once we get the result
    return (miss);
    #===
}

#========================================================
# Sub-routine before delivering final data
#========================================================
sub vcl_deliver {

    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
    #
    # You can do accounting or modifying the final object here.

    # Copy grace header from request
    # set resp.http.grace = req.http.grace;
    unset resp.http.grace;

    # Remove expire header and cache control from HTML pages
    # REALLY?
    # unset resp.http.expires;
    # unset resp.http.pragma;
    # unset resp.http.cache-control;
    
    # Remove cache control if it isn't needed
    if (resp.http.X-TYPO3-ProxyCaching ~ "1") {
	unset resp.http.cache-control;
    }

    # Display whether cache had a HIT or a MISS
    if (obj.hits > 0) {
	set resp.http.X-Cache = "HIT";
    } else {
	set resp.http.X-Cache = "MISS";
    }

    # Remove entries related to Varnish-Extension and RKW Basics
    # unset resp.http.xtag;
    # unset resp.http.X-TYPO3-ProxyCaching;

    # related to Varnish
    unset resp.http.X-Varnish;
    unset resp.http.Via;
    # unset resp.http.Age;

    # other stuff
    unset resp.http.X-Powered-By;
    set resp.http.X-Powered-By = "Steffen Kroggel and RKW Kompetenzzentrum on vm1.rkw.de";
    unset resp.http.Etag;

    # Fix for PDF bug in Acrobat Viewer Plugin 10.1.3 - force download
    # Do NOT combine with forced download for Apache! 
    if (
        (resp.http.content-type ~ "application/pdf")
        && (! resp.http.content-transfer-encoding ~ "binary")
    )  {
	set resp.http.content-type = "application/octet-stream";
	set resp.http.content-disposition = "attachment";
    }    
}

#========================================================
# Error page if backend is not reachable
#========================================================
sub vcl_backend_error {

    set beresp.http.Content-Type = "text/html; charset=utf-8";
    set beresp.http.Retry-After = "5";

    synthetic( {"
	<!DOCTYPE html>
	<html lang="de-DE">
	    <head>
	    <meta charset="utf-8">
	    <meta name="robots" content="noindex, nofollow">
	    <title>"} + beresp.status + " " + beresp.reason + {"</title>
	    <script src="https://use.typekit.net/frq0css.js"></script>
	    <script>try{Typekit.load();}catch(e){}</script>
	    <style>
	    * {
		margin: 0px;
		padding: 0px;
	    }
	    html {
		overflow-y: scroll;
		height: auto;
		min-height: 100%;
	    }
	    body {
		height: 100%;
		min-height: 100%;
		background: #E6E6E6 none repeat scroll 0% 0%;
		color: #333;
		font-family: "ff-tisa-web-pro","Times New Roman","Times",serif;
		font-size: 20px;
		font-weight: normal;
		line-height: 32px;
	    }
	    .container {
		margin: 0px auto;
		position: relative;
		max-width: 800px;
		padding:16px;
		padding-top:32px;
	    }
	    h1 {
		color: #333;
		font-family: "ff-tisa-sans-web-pro","Arial","Tahoma","Verdana",sans-serif;
		font-style: normal;
		font-weight: normal;
		text-rendering: optimizelegibility;
		margin-bottom:18px;
	    }
	    p {
		font-size: 20px;
		font-weight: normal;
		line-height: 32px;
		text-rendering: optimizelegibility;
		word-wrap: break-word;
		margin-bottom:10px;
	    }
	    a {
		color:#E64415;
	    }
	    </style>
	    </head>
	    <body>
		<div class="container">
		<h1>Fehler: "} + beresp.status + " " + beresp.reason + {"</h1>
		<p>Die angeforderte Seite kann aus technischen Gründen im Moment nicht angezeigt werden.</p>
		<p>Wir arbeiten bereits an einer Lösung. Bitte probieren Sie es in Kürze noch einmal.</p>
		<p>Sie erreichen unseren Support unter <a href="mailto:service@rkw.de">service@rkw.de</a>.</p>
		<p>&nbsp;</p>
		<p>&nbsp;</p>
		<h1>Error: "} + beresp.status + " " + beresp.reason + {"</h1>
		<p>For technical reasons the requested page is temporarily not available.</p>
		<p>We are already working on a solution. Please try again later.</p>
		<p>You can contact our support at <a href="mailto:service@rkw.de">service@rkw.de</a>.</p>
		</div>
	    </body>
	</html>
    "});

    return (deliver);
    #===

}

