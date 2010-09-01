# Redirect non-www to wwww
server {
  listen          80;
  server_name     socialintrigue.com;
  rewrite ^/(.*)  http://www.socialintrigue.com/$1 permanent;
}

server {
  listen      80;
  server_name *.socialintrigue.com;

  # passenger options
  passenger_enabled on;    	
  rails_env production;

  access_log  /Users/sanjay/Rails/social/log/access.log;
  error_log   /Users/sanjay/Rails/social/log/error.log;

  root        /Users/sanjay/Rails/social/public/;

  location ~* \.(ico|css|js|gif|jp?g|png)(\?[0-9]+)?$ {
    expires max;
    break;
  }

  # This rewrites all the requests to the maintenance.html page if it exists in the doc root.
  # This is for capistrano's disable web task.
  error_page   500 502 504  /500.html;
  error_page   503 @503;
  location @503 {
    rewrite  ^(.*)$  /system/maintenance.html break;
  }

  if (-f $document_root/system/maintenance.html) {
    return 503;
  }
}
