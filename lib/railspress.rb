require 'railspress/main_app_hook'
require "railspress/engine"

module Railspress

  include ActiveSupport::Configurable

#  config_accessor :post_type_meta_caps, :wp_rewrite, :multi_language

  cattr_accessor :ABSPATH
  cattr_accessor :SERVERPATH
  cattr_accessor :WPINC
# In WordPress, it can be set in wp-config.php like this: define('UPLOADS', 'images');
  cattr_accessor :UPLOADS
# When this flag is set, some debug information is written in templates as hidden inputs, or in the console.
  cattr_accessor :WP_DEBUG
# WP_CONTENT_DIR = ABSPATH + 'wp-content'
  cattr_accessor :WP_CONTENT_DIR
# WP_PLUGIN_DIR = WP_CONTENT_DIR . '/plugins'
# full path, no trailing slash
  cattr_accessor :WP_PLUGIN_DIR

# WP_CONTENT_URL = get_option('siteurl') + '/wp-content'
# full url - WP_CONTENT_DIR is defined further up
  cattr_accessor :WP_CONTENT_URL
# WP_PLUGIN_URL = WP_CONTENT_URL + '/plugins'
# full url, no trailing slash
  cattr_accessor :WP_PLUGIN_URL

  cattr_accessor :WP_POST_REVISIONS

# Relative to ABSPATH. For back compat.
# cattr_accessor :PLUGINDIR "wp-content/plugins"

  cattr_accessor :TS_READONLY_OPTIONS
  cattr_accessor :TS_EDITABLE_OPTIONS
  cattr_accessor :GLOBAL
  cattr_accessor :main_app_hook

# add default values of more config vars here
# def initialize
  self.WPINC = "wp-includes"
  self.UPLOADS = nil # must be nil if the constant is not set in WordPress in wp-config.php
  self.SERVERPATH = nil
  self.WP_DEBUG = false
  self.WP_PLUGIN_DIR = "wp-content/plugins"
  self.GLOBAL = Railspress::GlobalVars.new

  config_accessor :multi_language, :links_to_wp, :generate_breadcrumb, :posts_permalink_prefix, :pages_permalink_prefix

#  self.post_type_meta_caps = {}

 # self.wp_rewrite = Railspress::WpRewrite.new

  self.multi_language = false
  self.links_to_wp = false
  self.generate_breadcrumb = false

  # see permalink_structure/get_post_type_archive_link('post')
  self.posts_permalink_prefix = nil

  self.pages_permalink_prefix = nil

end
