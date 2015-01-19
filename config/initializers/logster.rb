if Rails.env.production?
  Logster.store.ignore = [
    # honestly, Rails should not be logging this, its real noisy
    /^ActionController::RoutingError \(No route matches/,

    /^PG::Error: ERROR:\s+duplicate key/,

    /^ActionController::UnknownFormat/,

    # some old browsers don't define the JavaScript console
    #
    # 'console' is undefined
    # Url: http://discourse-cdn.codinghorror.com/assets/vendor-0dbc6e71b0ee5428574e3562afe91ef1.js
    # Line: 16
    # Window Location: http://discourse.codinghorror.com/t/the-non-programming-programmer/120/2
    #
    /^'console' is undefined/,

    # ignore any empty JS errors that contain blanks or zeros for line and column fields
    #
    # Line:
    # Column:
    #
    /(?m).*?Line: (?:\D|0).*?Column: (?:\D|0)/,

    # suppress trackback spam bots
    Logster::IgnorePattern.new("Can't verify CSRF token authenticity", { REQUEST_URI: /\/trackback\/$/ }),
    # suppress trackback spam bots submitting to random URLs
    # test for the presence of these params: url, title, excerpt, blog_name
    Logster::IgnorePattern.new("Can't verify CSRF token authenticity", { params: { url: /./, title: /./, excerpt: /./, blog_name: /./} },

    # API calls, TODO fix this in rails
    Logster::IgnorePattern.new("Can't verify CSRF token authenticity", { REQUEST_URI: /api_key/ })
  ]
end

# middleware that logs errors sits before multisite
# we need to establish a connection so redis connection is good
# and db connection is good
Logster.config.current_context = lambda{|env,&blk|
  begin
    if Rails.configuration.multisite
      request = Rack::Request.new(env)
      ActiveRecord::Base.connection_handler.clear_active_connections!
      RailsMultisite::ConnectionManagement.establish_connection(:host => request['__ws'] || request.host)
    end
    blk.call
  ensure
    ActiveRecord::Base.connection_handler.clear_active_connections!
  end
}
