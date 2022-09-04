=begin
 * Core Taxonomy API
 *
 * file wp-includes\taxonomy.php
=end
require 'railspress/functions'
module Railspress::TaxonomyLib

  include Railspress::OptionsHelper
  include Railspress::Functions
  include Railspress::Plugin

  # Creates the initial taxonomies.
  #
  # This function fires twice: in wp-settings.php before plugins are loaded (for
  # backward compatibility reasons), and again on the {@see 'init'} action. We must
  # avoid registering rewrite rules before the {@see 'init'} action.
  def create_initial_taxonomies
    if false # ! did_action( 'init' )  ...
    rewrite = {
        category:    false,
        post_tag:    false,
        post_format: false,
    }
    else
      # Filters the post formats rewrite base.
      post_format_base = apply_filters('post_format_rewrite_base', 'type')
      rewrite = {
          category: {
              'hierarchical' => true,
              'slug' => get_option('category_base').blank? ? 'category' : get_option('category_base') ,
              'with_front' => !get_option('category_base') || Railspress.GLOBAL.wp_rewrite.using_index_permalinks,
              'ep_mask' => :EP_CATEGORIES,
          },
          post_tag: {
              'hierarchical' => false,
              'slug' => get_option('tag_base').blank? ? 'tag' : get_option('tag_base'),
              'with_front' => !get_option('tag_base') || Railspress.GLOBAL.wp_rewrite.using_index_permalinks,
              'ep_mask' => :EP_TAGS,
          },
          post_format: post_format_base ? {'slug' => post_format_base} : false,
      }
      # The below lines fix the wp_rewrite.extra_permastructs[...][struct] value. It was not prefixed with @front, but with @root
      rewrite[:category].delete('with_front') if rewrite[:category]['with_front'].nil?
      rewrite[:post_tag].delete('with_front') if rewrite[:post_tag]['with_front'].nil?
    end
    register_taxonomy('category',
                      'post',
                      {
                          'hierarchical' => true,
                          'query_var' => 'category_name',
                          'rewrite' => rewrite[:category],
                          'public' => true,
                          'show_ui' => true,
                          'show_admin_column' => true,
                          '_builtin' => true,
                          'capabilities' => {
                              'manage_terms' => 'manage_categories',
                              'edit_terms' => 'edit_categories',
                              'delete_terms' => 'delete_categories',
                              'assign_terms' => 'assign_categories',
                          },
                          'show_in_rest' => true,
                          'rest_base' => 'categories',
                          'rest_controller_class' => 'WP_REST_Terms_Controller',
                      }
    )
    register_taxonomy('post_tag',
                      'post',
                      {
                          'hierarchical' => false,
                          'query_var' => 'tag',
                          'rewrite' => rewrite[:post_tag],
                          'public' => true,
                          'show_ui' => true,
                          'show_admin_column' => true,
                          '_builtin' => true,
                          'capabilities' => {
                              'manage_terms' => 'manage_post_tags',
                              'edit_terms' => 'edit_post_tags',
                              'delete_terms' => 'delete_post_tags',
                              'assign_terms' => 'assign_post_tags',
                          },
                          'show_in_rest' => true,
                          'rest_base' => 'tags',
                          'rest_controller_class' => 'WP_REST_Terms_Controller',
                      }
    )
    register_taxonomy('nav_menu',
                      'nav_menu_item',
                      {
                          'public' => false,
                          'hierarchical' => false,
                          'labels' => {
                              # 'name'          => __( 'Navigation Menus' ),
                              # 'singular_name' => __( 'Navigation Menu' ),
                          },
                          'query_var' => false,
                          'rewrite' => false,
                          'show_ui' => false,
                          '_builtin' => true,
                          'show_in_nav_menus' => false,
                      }
    )
    register_taxonomy('link_category',
                      'link',
                      {
                          'hierarchical' => false,
                          'labels' => {
                              # 'name'                       => __( 'Link Categories' ),
                              # 'singular_name'              => __( 'Link Category' ),
                              # 'search_items'               => __( 'Search Link Categories' ),
                              # 'popular_items'              => null,
                              # 'all_items'                  => __( 'All Link Categories' ),
                              # 'edit_item'                  => __( 'Edit Link Category' ),
                              # 'update_item'                => __( 'Update Link Category' ),
                              # 'add_new_item'               => __( 'Add New Link Category' ),
                              # 'new_item_name'              => __( 'New Link Category Name' ),
                              # 'separate_items_with_commas' => null,
                              # 'add_or_remove_items'        => null,
                              # 'choose_from_most_used'      => null,
                              # 'back_to_items'              => __( '&larr; Back to Link Categories' ),
                          },
                          'capabilities' => {
                              'manage_terms' => 'manage_links',
                              'edit_terms' => 'manage_links',
                              'delete_terms' => 'manage_links',
                              'assign_terms' => 'manage_links',
                          },
                          'query_var' => false,
                          'rewrite' => false,
                          'public' => false,
                          'show_ui' => true,
                          '_builtin' => true,
                      }
    )
    register_taxonomy('post_format',
                      'post',
                      {
                          'public'            => true,
                          'hierarchical'      => false,
                          'labels'            => {
                              # 'name'          => _x( 'Formats', 'post format' ),
                              # 'singular_name' => _x( 'Format', 'post format' ),
                          },
                          'query_var'         => true,
                          'rewrite'           => rewrite[:post_format],
                          'show_ui'           => false,
                          '_builtin'          => true,
                      # TODO    'show_in_nav_menus' => current_theme_supports( 'post-formats' )
                      }
    )
  end

  # Retrieves a list of registered taxonomy names or objects.
  #
  # @param [array]  args     Optional. A hash of `key => value` arguments to match against the taxonomy objects.
  #                          Default empty hash.
  # @param [string] output   Optional. The type of output to return in the array. Accepts either taxonomy 'names'
  #                          or 'objects'. Default 'names'.
  # @param [string] operator Optional. The logical operation to perform. Accepts 'and' or 'or'. 'or' means only
  #                          one element from the array needs to match; 'and' means all elements must match.
  #                          Default 'and'.
  # @return string[]|WP_Taxonomy[] An array of taxonomy names or objects.
  def get_taxonomies( args = {}, output = 'names', operator = 'and' )
    field = ( 'names' == output ) ? 'name' : false
    return wp_filter_object_list(Railspress.GLOBAL.wp_taxonomies, args, operator, field)
    # if output == 'names'
    #   Railspress::Term.where(term_id: Railspress::Taxonomy.where(args).pluck(:term_id)).pluck(:name)
    # else
    #   Railspress::Taxonomy.where(args)
    # end
  end

  # Return the names or objects of the taxonomies which are registered for the requested object or object type, such as
  # a post object or post type name.
  #
  # Example:
  #
  #     taxonomies = get_object_taxonomies('post')
  #
  # This results in:
  #
  #     ['category', 'post_tag']
  #
  # @param [array|string|WP_Post] $object Name of the type of taxonomy object, or an object (row from posts)
  # @param [string]               $output Optional. The type of output to return in the array. Accepts either
  #                                     taxonomy 'names' or 'objects'. Default 'names'.
  # @return array The names of all taxonomy of $object_type.
  def get_object_taxonomies(object, output = 'names')
    if object.is_a? Railspress::WpPost
      return get_attachment_taxonomies(object, output) if (object.post_type == 'attachment')
      object = object.post_type
    end

    object = [object]

    taxonomies = 'names' == output ? [] : {}
    Railspress.GLOBAL.wp_taxonomies.each_pair do |tax_name, tax_obj|
      unless (object & tax_obj.object_type.to_a).blank?
        if 'names' == output
          taxonomies << tax_name
        else
          taxonomies[tax_name] = tax_obj
        end
      end
    end
    taxonomies
  end

  # Retrieves the taxonomy object of taxonomy.
  #
  # The get_taxonomy function will first check that the parameter string given
  # is a taxonomy object and if it is, it will return it.
  #
  # @global array $wp_taxonomies The registered taxonomies.
  #
  # @param [String] taxonomy Name of taxonomy object to return.
  # @return WP_Taxonomy|false The Taxonomy Object or false if $taxonomy doesn't exist.
  def get_taxonomy(taxonomy)
    # global $wp_taxonomies

    # return false unless taxonomy_exists(taxonomy)
    global_tax = Railspress.GLOBAL.wp_taxonomies[taxonomy]
    return global_tax unless global_tax.nil?

    Railspress::Taxonomy.where(taxonomy: taxonomy).first
  end

  # Determines whether the taxonomy name exists.
  #
  # Formerly is_taxonomy(), introduced in 2.3.0.
  #
  # For more information on this and similar theme functions, check out
  # the {@link https://developer.wordpress.org/themes/basics/conditional-tags/
  # Conditional Tags} article in the Theme Developer Handbook.
  #
  # @param [String] taxonomy Name of taxonomy object.
  # @return bool Whether the taxonomy exists.
  def taxonomy_exists(taxonomy)
    return true unless Railspress.GLOBAL.wp_taxonomies[taxonomy].nil?
    Railspress::Taxonomy.exists? taxonomy: taxonomy
  end

  # Creates or modifies a taxonomy object.
  #
  # Note: Do not use before the {@see 'init'} hook.
  #
  # A simple function for creating or modifying a taxonomy object based on
  # the parameters given. If modifying an existing taxonomy object, note
  # that the `$object_type` value from the original registration will be
  # overwritten.
  # @param [string]       taxonomy    Taxonomy key, must not exceed 32 characters.
  # @param [array|string] object_type Object type or array of object types with which the taxonomy should be associated.
  # @param [array|string] args        {
  #     Optional. Array or query string of arguments for registering a taxonomy.
  #
  #     @type array         $labels                An array of labels for this taxonomy. By default, Tag labels are
  #                                                used for non-hierarchical taxonomies, and Category labels are used
  #                                                for hierarchical taxonomies. See accepted values in
  #                                                get_taxonomy_labels(). Default empty array.
  #     @type string        $description           A short descriptive summary of what the taxonomy is for. Default empty.
  #     @type bool          $public                Whether a taxonomy is intended for use publicly either via
  #                                                the admin interface or by front-end users. The default settings
  #                                                of `$publicly_queryable`, `$show_ui`, and `$show_in_nav_menus`
  #                                                are inherited from `$public`.
  #     @type bool          $publicly_queryable    Whether the taxonomy is publicly queryable.
  #                                                If not set, the default is inherited from `$public`
  #     @type bool          $hierarchical          Whether the taxonomy is hierarchical. Default false.
  #     @type bool          $show_ui               Whether to generate and allow a UI for managing terms in this taxonomy in
  #                                                the admin. If not set, the default is inherited from `$public`
  #                                                (default true).
  #     @type bool          $show_in_menu          Whether to show the taxonomy in the admin menu. If true, the taxonomy is
  #                                                shown as a submenu of the object type menu. If false, no menu is shown.
  #                                                `$show_ui` must be true. If not set, default is inherited from `$show_ui`
  #                                                (default true).
  #     @type bool          $show_in_nav_menus     Makes this taxonomy available for selection in navigation menus. If not
  #                                                set, the default is inherited from `$public` (default true).
  #     @type bool          $show_in_rest          Whether to include the taxonomy in the REST API.
  #     @type string        $rest_base             To change the base url of REST API route. Default is $taxonomy.
  #     @type string        $rest_controller_class REST API Controller class name. Default is 'WP_REST_Terms_Controller'.
  #     @type bool          $show_tagcloud         Whether to list the taxonomy in the Tag Cloud Widget controls. If not set,
  #                                                the default is inherited from `$show_ui` (default true).
  #     @type bool          $show_in_quick_edit    Whether to show the taxonomy in the quick/bulk edit panel. It not set,
  #                                                the default is inherited from `$show_ui` (default true).
  #     @type bool          $show_admin_column     Whether to display a column for the taxonomy on its post type listing
  #                                                screens. Default false.
  #     @type bool|callable $meta_box_cb           Provide a callback function for the meta box display. If not set,
  #                                                post_categories_meta_box() is used for hierarchical taxonomies, and
  #                                                post_tags_meta_box() is used for non-hierarchical. If false, no meta
  #                                                box is shown.
  #     @type callable      $meta_box_sanitize_cb  Callback function for sanitizing taxonomy data saved from a meta
  #                                                box. If no callback is defined, an appropriate one is determined
  #                                                based on the value of `$meta_box_cb`.
  #     @type array         $capabilities {
  #         Array of capabilities for this taxonomy.
  #
  #         @type string $manage_terms Default 'manage_categories'.
  #         @type string $edit_terms   Default 'manage_categories'.
  #         @type string $delete_terms Default 'manage_categories'.
  #         @type string $assign_terms Default 'edit_posts'.
  #     }
  #     @type bool|array    $rewrite {
  #         Triggers the handling of rewrites for this taxonomy. Default true, using $taxonomy as slug. To prevent
  #         rewrite, set to false. To specify rewrite rules, an array can be passed with any of these keys:
  #
  #         @type string $slug         Customize the permastruct slug. Default `$taxonomy` key.
  #         @type bool   $with_front   Should the permastruct be prepended with WP_Rewrite::$front. Default true.
  #         @type bool   $hierarchical Either hierarchical rewrite tag or not. Default false.
  #         @type int    $ep_mask      Assign an endpoint mask. Default `EP_NONE`.
  #     }
  #     @type string        $query_var             Sets the query var key for this taxonomy. Default `$taxonomy` key. If
  #                                                false, a taxonomy cannot be loaded at `?{query_var}={term_slug}`. If a
  #                                                string, the query `?{query_var}={term_slug}` will be valid.
  #     @type callable      $update_count_callback Works much like a hook, in that it will be called when the count is
  #                                                updated. Default _update_post_term_count() for taxonomies attached
  #                                                to post types, which confirms that the objects are published before
  #                                                counting them. Default _update_generic_term_count() for taxonomies
  #                                                attached to other object types, such as users.
  #     @type bool          $_builtin              This taxonomy is a "built-in" taxonomy. INTERNAL USE ONLY!
  #                                                Default false.
  # }
  # @return WpError|void WpError, if errors.
  def register_taxonomy(taxonomy, object_type, args = {})
    Railspress.GLOBAL.wp_taxonomies = {} if Railspress.GLOBAL.wp_taxonomies.nil?
    args = Railspress::Functions.wp_parse_args( args )

    if taxonomy.blank? || taxonomy.length > 32
      # _doing_it_wrong( __FUNCTION__, __( 'Taxonomy names must be between 1 and 32 characters in length.' ), '4.2.0' )
      return Railspress::WpError.new( 'taxonomy_length_invalid', ( 'Taxonomy names must be between 1 and 32 characters in length.' ) )
    end
    # TODO continue WP_Taxonomy

    taxonomy_object = Railspress::Taxonomy.new({taxonomy: taxonomy})
    taxonomy_object.set_props(object_type, args)
    taxonomy_object.add_rewrite_rules

    Railspress.GLOBAL.wp_taxonomies[ taxonomy ] = taxonomy_object

    taxonomy_object.add_hooks

    # Fires after a taxonomy is registered.
    do_action( 'registered_taxonomy', taxonomy, object_type, taxonomy_object)
  end

  # TODO unregister_taxonomy()

  # Builds an object with all taxonomy labels out of a taxonomy object.
  #
  # @param [WP_Taxonomy] tax Taxonomy object.
  # @return object {
  #     Taxonomy labels object. The first default value is for non-hierarchical taxonomies
  #     (like tags) and the second one is for hierarchical taxonomies (like categories).
  #
  #     @type string $name                       General name for the taxonomy, usually plural. The same
  #                                              as and overridden by `$tax->label`. Default 'Tags'/'Categories'.
  #     @type string $singular_name              Name for one object of this taxonomy. Default 'Tag'/'Category'.
  #     @type string $search_items               Default 'Search Tags'/'Search Categories'.
  #     @type string $popular_items              This label is only used for non-hierarchical taxonomies.
  #                                              Default 'Popular Tags'.
  #     @type string $all_items                  Default 'All Tags'/'All Categories'.
  #     @type string $parent_item                This label is only used for hierarchical taxonomies. Default
  #                                              'Parent Category'.
  #     @type string $parent_item_colon          The same as `parent_item`, but with colon `:` in the end.
  #     @type string $edit_item                  Default 'Edit Tag'/'Edit Category'.
  #     @type string $view_item                  Default 'View Tag'/'View Category'.
  #     @type string $update_item                Default 'Update Tag'/'Update Category'.
  #     @type string $add_new_item               Default 'Add New Tag'/'Add New Category'.
  #     @type string $new_item_name              Default 'New Tag Name'/'New Category Name'.
  #     @type string $separate_items_with_commas This label is only used for non-hierarchical taxonomies. Default
  #                                              'Separate tags with commas', used in the meta box.
  #     @type string $add_or_remove_items        This label is only used for non-hierarchical taxonomies. Default
  #                                              'Add or remove tags', used in the meta box when JavaScript
  #                                              is disabled.
  #     @type string $choose_from_most_used      This label is only used on non-hierarchical taxonomies. Default
  #                                              'Choose from the most used tags', used in the meta box.
  #     @type string $not_found                  Default 'No tags found'/'No categories found', used in
  #                                              the meta box and taxonomy list table.
  #     @type string $no_terms                   Default 'No tags'/'No categories', used in the posts and media
  #                                              list tables.
  #     @type string $items_list_navigation      Label for the table pagination hidden heading.
  #     @type string $items_list                 Label for the table hidden heading.
  #     @type string $most_used                  Title for the Most Used tab. Default 'Most Used'.
  #     @type string $back_to_items              Label displayed after a term has been updated.
  # }
  def get_taxonomy_labels( tax )
    # tax.labels = (array) $tax->labels

    # if ( !tax.helps.nil? && tax.labels['separate_items_with_commas'].blank? )
    #   tax.labels['separate_items_with_commas'] = tax.helps
    # end
    #
    # if ( !tax.no_tagcloud.nil? && tax.labels['not_found'].blank? )
    #   tax.labels['not_found'] = tax.no_tagcloud
    # end

    nohier_vs_hier_defaults = {
        'name'                       => ['Tags', 'Categories'],
        'singular_name'              => ['Tag', 'Category']
      #  'search_items'               => array( __( 'Search Tags' ), __( 'Search Categories' ) ),
      #  'popular_items'              => array( __( 'Popular Tags' ), null ),
      #  'all_items'                  => array( __( 'All Tags' ), __( 'All Categories' ) ),
      #  'parent_item'                => array( null, __( 'Parent Category' ) ),
      #  'parent_item_colon'          => array( null, __( 'Parent Category:' ) ),
      #  'edit_item'                  => array( __( 'Edit Tag' ), __( 'Edit Category' ) ),
      #  'view_item'                  => array( __( 'View Tag' ), __( 'View Category' ) ),
      #  'update_item'                => array( __( 'Update Tag' ), __( 'Update Category' ) ),
      #  'add_new_item'               => array( __( 'Add New Tag' ), __( 'Add New Category' ) ),
      #  'new_item_name'              => array( __( 'New Tag Name' ), __( 'New Category Name' ) ),
      #  'separate_items_with_commas' => array( __( 'Separate tags with commas' ), null ),
      #  'add_or_remove_items'        => array( __( 'Add or remove tags' ), null ),
      #  'choose_from_most_used'      => array( __( 'Choose from the most used tags' ), null ),
      #  'not_found'                  => array( __( 'No tags found.' ), __( 'No categories found.' ) ),
      #  'no_terms'                   => array( __( 'No tags' ), __( 'No categories' ) ),
      #  'items_list_navigation'      => array( __( 'Tags list navigation' ), __( 'Categories list navigation' ) ),
      #  'items_list'                 => array( __( 'Tags list' ), __( 'Categories list' ) ),
      #  # translators: Tab heading when selecting from the most used terms 
      # 'most_used'                  => array( _x( 'Most Used', 'tags' ), _x( 'Most Used', 'categories' ) ),
      #  'back_to_items'              => array( __( '&larr; Back to Tags' ), __( '&larr; Back to Categories' ) ),
    }
    nohier_vs_hier_defaults['menu_name'] = nohier_vs_hier_defaults['name']

    labels = Railspress::PostsHelper._get_custom_object_labels( tax, nohier_vs_hier_defaults )

    # taxonomy = tax.name
    #
    # default_labels = clone labels
    #
    # Filters the labels of a specific taxonomy.
    #
    # The dynamic portion of the hook name, `$taxonomy`, refers to the taxonomy slug.
    #
    # labels = apply_filters( "taxonomy_labels_{$taxonomy}", $labels );
    # 
    # Ensure that the filtered labels contain all required default values.
    # labels = array_merge(  default_labels,  labels )
    labels
  end

  def get_post_type_object(post_type) # copied from PostsHelper, because it could not access it otherwise
    if !RailspressPhp.is_scalar(post_type) || Railspress.GLOBAL.wp_post_types[post_type].blank?
      return nil
    end
    Railspress.GLOBAL.wp_post_types[post_type]
  end

  # Add an already registered taxonomy to an object type.
  #
  # @global array $wp_taxonomies The registered taxonomies.
  #
  # @param [string] taxonomy    Name of taxonomy object.
  # @param [string] object_type Name of the object type.
  # @return bool True if successful, false if not.
  def register_taxonomy_for_object_type(taxonomy, object_type)

    return false if Railspress.GLOBAL.wp_taxonomies[taxonomy].nil?
    return false if !get_post_type_object(object_type)

    unless Railspress.GLOBAL.wp_taxonomies[ taxonomy ].object_type.include?( object_type )
      Railspress.GLOBAL.wp_taxonomies[ taxonomy ].object_type << object_type
    end

    # Filter out empties.
    Railspress.GLOBAL.wp_taxonomies[ taxonomy ].object_type.select! {|ot| !ot.blank? }

    # Fires after a taxonomy is registered for an object type.
    do_action( 'registered_taxonomy_for_object_type', taxonomy, object_type)

    true
  end

  # Remove an already registered taxonomy from an object type.
  #
  # @param [string] taxonomy    Name of taxonomy object.
  # @param [string] object_type Name of the object type.
  # @return [bool] True if successful, false if not.
  def unregister_taxonomy_for_object_type(taxonomy, object_type)
    return false if Railspress.GLOBAL.wp_taxonomies[taxonomy].nil?
    return false if !get_post_type_object(object_type)

    if Railspress.GLOBAL.wp_taxonomies[taxonomy].object_type.include? object_type
      Railspress.GLOBAL.wp_taxonomies[taxonomy].object_type.delete(object_type)
    else
      return false
    end

    # Fires after a taxonomy is unregistered for an object type.
    do_action('unregistered_taxonomy_for_object_type', taxonomy, object_type)

    true
  end

  ##
  ## Term API
  ##

  # Get all Term data from database by Term ID.
  #
  # The usage of the get_term function is to apply filters to a term object. It
  # is possible to get a term object from the database before applying the
  # filters.
  #
  # $term ID must be part of $taxonomy, to get from the database. Failure, might
  # be able to be captured by the hooks. Failure would be the same value as $wpdb
  # returns for the get_row method.
  #
  # There are two hooks, one is specifically for each term, named 'get_term', and
  # the second is for the taxonomy name, 'term_$taxonomy'. Both hooks gets the
  # term object, and the taxonomy name as parameters. Both hooks are expected to
  # return a Term object.
  #
  # {@see 'get_term'} hook - Takes two parameters the term Object and the taxonomy name.
  # Must return term object. Used in get_term() as a catch-all filter for every
  # $term.
  #
  # {@see 'get_$taxonomy'} hook - Takes two parameters the term Object and the taxonomy
  # name. Must return term object. $taxonomy will be the taxonomy name, so for
  # example, if 'category', it would be 'get_category' as the filter name. Useful
  # for custom taxonomies or plugging into default taxonomies.
  #
  # @see sanitize_term_field() The $context param lists the available values for get_term_by() $filter param.
  #
  # @param [int|WP_Term|object] term If integer, term data will be fetched from the database, or from the cache if
  #                                  available. If stdClass object (as in the results of a database query), will apply
  #                                  filters and return a `WP_Term` object corresponding to the `$term` data. If `WP_Term`,
  #                                  will return `$term`.
  # @param [string]     taxonomy Optional. Taxonomy name that $term is part of.
  # @param [string]     output   Optional. The required return type. One of OBJECT, ARRAY_A, or ARRAY_N, which correspond to
  #                              a WP_Term object, an associative array, or a numeric array, respectively. Default OBJECT.
  # @param [string]     filter   Optional, default is raw or no WordPress defined filter will applied.
  # @return array|WP_Term|WpError|null Object of the type specified by `$output` on success. When `$output` is 'OBJECT',
  #                                     a WP_Term instance is returned. If taxonomy does not exist, a WpError is
  #                                     returned. Returns null for miscellaneous failure.
  def get_term(term, taxonomy = '', output = :OBJECT, filter = 'raw' )
    return WpError.new('invalid_term', I18n.t('railspress.invalid_term')) if term.blank?

    if !taxonomy.blank? && !taxonomy_exists(taxonomy)
      return WpError.new('invalid_taxonomy', I18n.t('railspress.invalid_taxonomy'))
    end

    if term.is_a? Railspress::Term
      _term = term
    elsif term.is_a?(Integer) || term.is_a?(String)
      if term.to_i == 0
        _term = nil
      else
        _term = Railspress::Term.find(term.to_i)
      end
    else
      if !term.respond_to?(filter) || term.filter.blank? || 'raw' == term.filter
        _term = sanitize_term(term, taxonomy, 'raw')
        if _term.is_a?(Hash)
          _term = Railspress::Term.new(_term)
        end
      else
        _term = Railspress::Term.find(term.term_id)
      end
    end

    if _term.is_a? Railspress::WpError
      return _term
    elsif _term.nil?
      return nil
    end

    # Ensure for filters that this is not empty.
    taxonomy = _term.taxonomy

    # Filters a taxonomy term object.
    _term = apply_filters('get_term', _term, taxonomy)

    # Filters a taxonomy term object.
    _term = apply_filters("get_#{taxonomy}", _term, taxonomy)

    # Bail if a filter callback has changed the type of the `$_term` object.
    return _term unless _term.is_a? Railspress::Term

    # Sanitize term, according to the specified filter.
    _term.filter(filter)

    # TODO :ARRAY_A / :ARRAY_N
    if output == :ARRAY_A
      return _term.to_array()
    elsif output == :ARRAY_N
      return array_values(_term.to_array())
    end

    _term
  end

  # Get all Term data from database by Term field and data.
  #
  # Warning: $value is not escaped for 'name' $field. You must do it yourself, if
  # required.
  #
  # The default $field is 'id', therefore it is possible to also use null for
  # field, but not recommended that you do so.
  #
  # If $value does not exist, the return value will be false. If $taxonomy exists
  # and $field and $value combinations exist, the Term will be returned.
  #
  # This function will always return the first term that matches the `$field`-
  # `$value`-`$taxonomy` combination specified in the parameters. If your query
  # is likely to match more than one term (as is likely to be the case when
  # `$field` is 'name', for example), consider using get_terms() instead; that
  # way, you will get all matching terms, and can provide your own logic for
  # deciding which one was intended.
  #
  # @see sanitize_term_field() The $context param lists the available values for get_term_by() $filter param.
  #
  # @param [string]     field    Either 'slug', 'name', 'id' (term_id), or 'term_taxonomy_id'
  # @param [string|int] value    Search for this term value
  # @param [string]     taxonomy Taxonomy name. Optional, if `$field` is 'term_taxonomy_id'.
  # @param [string]     output   Optional. The required return type. One of OBJECT, ARRAY_A, or ARRAY_N, which correspond to
  #                              a WP_Term object, an associative array, or a numeric array, respectively. Default OBJECT.
  # @param [string]     filter   Optional, default is raw or no WordPress defined filter will applied.
  # @return [WP_Term|array|false] WP_Term instance (or array) on success. Will return false if `$taxonomy` does not exist
  #                              or `$term` was not found.
  def get_term_by(field, value, taxonomy = '', output = :OBJECT, filter = 'raw' )

    # 'term_taxonomy_id' lookups don't require taxonomy checks.
    if :term_taxonomy_id != field && !taxonomy_exists(taxonomy)
      return false
    end

    # No need to perform a query for empty 'slug' or 'name'.
    if :slug == field || :name == field
      value = value.to_s

      return false if value == ''
    end

    if :id == field || :term_id == field
      term = get_term(value.to_i, taxonomy, output, filter)

      term = false if term.is_a?(Railspress::WpError) || term.nil?

      return term
    end

    args = {
        get:                    'all',
        number:                 1,
        taxonomy:               taxonomy,
        update_term_meta_cache: false,
        orderby:                'none',
        suppress_filter:        true
    }

    case field
    when :slug
      args[:slug] = value
    when :name
      args[:name] = value
    when :term_taxonomy_id
      args[:term_taxonomy_id] = value
      args.remove :taxonomy
    else
      return false
    end

    terms = get_terms(args)
    return false  if  terms.is_a?(Railspress::WpError) || terms.blank?

    term = terms.to_a.shift

    # In the case of 'term_taxonomy_id', override the provided `$taxonomy` with whatever we find in the db.
    if :term_taxonomy_id == field
      taxonomy = term.taxonomy
    end

    get_term(term, taxonomy, output, filter)
  end

  # TODO get_term_children

  # Get sanitized Term field.
  #
  # The function is for contextual reasons and for simplicity of usage.
  #
  # @see sanitize_term_field()
  #
  # @param [string]      field    Term field to fetch.
  # @param [int|WP_Term] term     Term ID or object.
  # @param [string]      taxonomy Optional. Taxonomy Name. Default empty.
  # @param [string]      context  Optional, default is display. Look at sanitize_term_field() for available options.
  # @return [string|int|null|WpError] Will return an empty string if $term is not an object or if $field is not set in $term.
  def get_term_field( field, term, taxonomy = '', context = 'display' )
    term = get_term( term, taxonomy )
    return term if term.is_a?(Railspress::WpError)

    return '' unless term.is_a? Object

    return '' if term.send(field).nil?

    sanitize_term_field( field, term.send(field), term.term_id, term.taxonomy, context )
  end

  # TODO get_term_to_edit

  # Retrieve the terms in a given taxonomy or list of taxonomies.
  #
  # You can fully inject any customizations to the query before it is sent, as
  # well as control the output with a filter.
  #
  # The {@see 'get_terms'} filter will be called when the cache has the term and will
  # pass the found term along with the array of $taxonomies and array of $args.
  # This filter is also called before the array of terms is passed and will pass
  # the array of terms, along with the $taxonomies and $args.
  #
  # The {@see 'list_terms_exclusions'} filter passes the compiled exclusions along with
  # the $args.
  #
  # The {@see 'get_terms_orderby'} filter passes the `ORDER BY` clause for the query
  # along with the $args array.
  #
  # @param [string|array] args       Optional. Array or string of arguments. See WP_Term_Query::__construct()
  #                                  for information on accepted arguments. Default empty.
  # @return [array|int|WpError] List of WP_Term instances and their children. Will return WpError, if any of $taxonomies
  #                              do not exist.
  def get_terms(args = {})
    term_query = {} # WP_Term_Query();

    defaults = {
        suppress_filter: false
    }

    args = Railspress::Functions.wp_parse_args(args, defaults)
    unless args[:taxonomy].nil?
      args[:taxonomy] =  [args[:taxonomy]]
    end

    unless args[:taxonomy].empty?
      args[:taxonomy].each do |taxonomy|
        return WpError.new('invalid_taxonomy', I18n.t('railspress.invalid_taxonomy')) unless taxonomy_exists(taxonomy)
      end
    end

    # Don't pass suppress_filter to WP_Term_Query.
    suppress_filter = args[:suppress_filter]
    args.delete(:suppress_filter)

    where_cond = args.slice(:slug, :name, :term_taxonomy_id)
    case args[:get]
    when 'all'
      terms = Railspress::Term.where(where_cond).all
    when 'count'
      terms = Railspress::Term.where(where_cond).count
    end

    # Count queries are not filtered, for legacy reasons.
    return terms unless terms.is_a? Array

    return terms if suppress_filter

    # Filters the found terms.
    apply_filters('get_terms', terms, term_query.query_vars['taxonomy'], term_query.query_vars, term_query)
  end

  # TODO add_term_meta delete_term_meta get_term_meta update_term_meta update_termmeta_cache has_term_meta register_term_meta unregister_term_meta term_exists term_is_ancestor_of

  # Sanitize Term all fields.
  #
  # Relies on sanitize_term_field() to sanitize the term. The difference is that
  # this function will sanitize <strong>all</strong> fields. The context is based
  # on sanitize_term_field().
  #
  # The $term is expected to be either an array or an object.
  #
  # @since 2.3.0
  #
  # @param [array|object] term     The term to check.
  # @param [string]       taxonomy The taxonomy name to use.
  # @param [string]       context  Optional. Context in which to sanitize the term. Accepts 'edit', 'db',
  #                                'display', 'attribute', or 'js'. Default 'display'.
  # @return [array|object] Term with all fields sanitized.
  def sanitize_term(term, taxonomy, context = 'display')
    # fields = ['term_id', 'name', 'description', 'slug', 'count', 'parent', 'term_group', 'term_taxonomy_id', 'object_id' ]

    do_object = !term.kind_of?(Hash)

    term_id = do_object ? term.term_id : (term['term_id'] || 0)

    term.attributes.each do |field|

      if do_object
        if !term.read_attribute(field).nil?
          term.write_attribute(field, sanitize_term_field(field, term.read_attribute(field), term_id, taxonomy, context))
        end
      else
        if !term[field].nil?
          term[field] = sanitize_term_field(field, term[field], term_id, taxonomy, context)
        end
      end
    end

    if do_object
      term.filter_str = context
    else
      term['filter'] = context
    end

    term
  end

  # Cleanse the field value in the term based on the context.
  #
  # Passing a term field value through the function should be assumed to have
  # cleansed the value for whatever context the term field is going to be used.
  #
  # If no context or an unsupported context is given, then default filters will
  # be applied.
  #
  # There are enough filters for each context to support a custom filtering
  # without creating your own filter function. Simply create a function that
  # hooks into the filter you need.
  #
  # @since 2.3.0
  #
  # @param [string] field    Term field to sanitize.
  # @param [string] value    Search for this term value.
  # @param [int]    term_id  Term ID.
  # @param [string] taxonomy Taxonomy Name.
  # @param [string] context  Context in which to sanitize the term field. Accepts 'edit', 'db', 'display',
  #                          'attribute', or 'js'.
  # @return mixed Sanitized field.
  def sanitize_term_field(field, value, term_id, taxonomy, context)
    int_fields = [:parent, :term_id, :count, :term_group, :term_taxonomy_id, :object_id]
    if int_fields.include? field
      value = value.to_i
      value = 0 if value < 0
    end

    return value if 'raw' == context

    if 'edit' == context

      # Filters a term field to edit before it is sanitized.
      value = apply_filters("edit_term_#{field}", value, term_id, taxonomy)

      # Filters the taxonomy field to edit before it is sanitized.
      value = apply_filters("edit_#{taxonomy}_#{field}", value, term_id)

      if 'description' == field
        value = esc_html(value) # textarea_escaped
      else
        value = esc_attr(value)
      end
    elsif 'db' == context

      # Filters a term field value before it is sanitized.
      value = apply_filters("pre_term_#{field}", value, taxonomy)

      # Filters a taxonomy field before it is sanitized.
      value = apply_filters("pre_#{taxonomy}_#{field}", value)

      # Back compat filters
      if :slug == field
        # Filters the category nicename before it is sanitized.
        value = apply_filters('pre_category_nicename', value)
      end
    elsif 'rss' == context

      # Filters the term field for use in RSS.
      value = apply_filters("term_#{field}_rss", value, taxonomy)

      # Filters the taxonomy field for use in RSS.
      value = apply_filters("#{taxonomy}_#{field}_rss", value)
    else
      # Use display filters by default.

      # Filters the term field sanitized for display.
      value = apply_filters("term_#{field}", value, term_id, taxonomy, context)

      # Filters the taxonomy field sanitized for display.
      value = apply_filters("#{taxonomy}_#{field}", value, term_id, context)
    end

    if 'attribute' == context
      value = esc_attr(value)
    elsif 'js' == context
      value = esc_js(value)
    end
    value
  end

  # Retrieves the terms associated with the given object(s), in the supplied taxonomies.
  #
  # @param [int|array]    object_ids The ID(s) of the object(s) to retrieve.
  # @param [string|array] taxonomies The taxonomies to retrieve terms from.
  # @param [array|string] args       See WP_Term_Query::__construct() for supported arguments.
  # @return [array|WpError] The requested term data or empty array if no terms found.
  #                        WpError if any of the taxonomies don't exist.
  def wp_get_object_terms(object_ids, taxonomies, args = {})
    return {} if object_ids.blank? or taxonomies.blank?

    unless taxonomies.is_a? Array
      taxonomies = [taxonomies]
    end

    # taxonomies.each do |taxonomy|
    #   unless taxonomy_exists(taxonomy)
    #     p "Taxonomy #{taxonomy} is invalid in #{taxonomies}"
    #     raise WpError.new('invalid_taxonomy', I18n.t('railspress.invalid_taxonomy'))
    #   end
    # end

    unless object_ids.is_a? Array
      object_ids = [object_ids]
    end
    object_ids = object_ids.map(&:to_i)

    args = Railspress::Functions.wp_parse_args(args)

    # Filter arguments for retrieving object terms.
    args = apply_filters('wp_get_object_terms_args', args, object_ids, taxonomies)

    # When one or more queried taxonomies is registered with an 'args' array,
    # those params override the `args` passed to this function.
    terms = []

    # added:
    if true
      taxonomies.each_with_index do |taxonomy, index|
        # terms += get_taxonomy(taxonomy)
        terms += Railspress::Taxonomy.joins(:posts).where(Railspress::Post.table_name => {id: object_ids}, taxonomy: taxonomy)
      end
      return terms # .select{|term_obj| object_ids.include? term_obj.post.id }
    end

    # TODO ???
    if taxonomies.size > 1
      taxonomies.each_with_index do |taxonomy, index|

        t = get_taxonomy(taxonomy)
        if !t.args.blank? && t.args.is_a?(Hash) && args != args.merge(t.args)
          taxonomies[index] = nil
          terms += wp_get_object_terms(object_ids, taxonomy, args.merge(t.args))
        end
      end
    else
      t = get_taxonomy(taxonomies[0])
      if !t.args.blank? && t.args.is_a?(Hash)
        args = args.merge t.args
      end
    end

    args['taxonomy'] = taxonomies
    args['object_ids'] = object_ids

    # Taxonomies registered without an 'args' param are handled here.
    if !taxonomies.blank?
      terms_from_remaining_taxonomies = get_terms(args)

      # Array keys should be preserved for values of fields that use term_id for keys.
      if !args['fields'].blank? && 0 == args['fields'].index('id=>')
        terms = terms + terms_from_remaining_taxonomies
      else
        terms = terms.merge terms_from_remaining_taxonomies
      end
    end

    # Filters the terms for a given object or objects.
    terms = apply_filters('get_object_terms', terms, object_ids, taxonomies, args)

    object_ids = object_ids.join(',')
    taxonomies.map(&:esc_url)
    taxonomies = "'" + taxonomies.map(&:esc_sql).join("', '") + "'"

    # Filters the terms for a given object or objects.
    apply_filters('wp_get_object_terms', terms, object_ids, taxonomies, args)
  end

  # Generate a permalink for a taxonomy term archive.
  #
  # @global WP_Rewrite $wp_rewrite
  #
  # @param [object|int|string] term     The term object, ID, or slug whose link will be retrieved.
  # @param [string]            taxonomy Optional. Taxonomy. Default empty.
  # @return [string|WpError] HTML link to taxonomy term archive on success, WpError if term does not exist.
  def get_term_link(term, taxonomy = '')
    # global $wp_rewrite;

    unless term.is_a? Railspress::Term
      if term.is_a? Integer
        term = get_term(term, taxonomy)
      elsif term.is_a? Railspress::PostTag
        term = get_term_by(:slug, term.term.slug, taxonomy)
      else
        term = get_term_by(:slug, term, taxonomy)
      end
    end
    if term.blank?
      term = Railspress::WpError.new('invalid_term', I18n.t('railspress.invalid_term'))
    end

    return term if term.is_a? Railspress::WpError

  #  taxonomy = term.taxonomy

    termlink = Railspress.GLOBAL.wp_rewrite.get_extra_permastruct(taxonomy)
    # Filters the permalink structure for a terms before token replacement occurs.
    termlink = apply_filters('pre_term_link', termlink, term)

    slug = term.slug
    t    = get_taxonomy(taxonomy)
    if termlink.blank?
      if 'category' == taxonomy
        termlink = {cat: term.term_id} # '?cat=' + term.term_id
      elsif t.query_var
        termlink = "?#{t.query_var}=#{slug}"
      else
        termlink =  {taxonomy: taxonomy, term: slug} # "?taxonomy=$taxonomy&term=$slug";
      end
      termlink = main_app.root_url(termlink)
    else
      if t.rewrite['hierarchical']
        hierarchical_slugs = []
        ancestors          = get_ancestors(term.term_id, taxonomy, 'taxonomy')
        ancestors.each do |ancestor|
          ancestor_term        = get_term(ancestor, taxonomy)
          hierarchical_slugs << ancestor_term.slug
        end
        hierarchical_slugs   = hierarchical_slugs.reverse
        hierarchical_slugs << slug
        termlink = termlink.gsub( "%#{taxonomy}%", hierarchical_slugs.join('/'))
      else
        termlink = termlink.gsub("%#{taxonomy}%", slug)
      end
      termlink = if Railspress.links_to_wp
                   home_url(user_trailingslashit(termlink, 'category'))
                 else
                   untrailingslashit(main_app.root_url) + termlink
                 end
    end
    # Back Compat filters.
    if 'post_tag' == taxonomy

      # Filters the tag link.
      termlink = apply_filters('tag_link', termlink, term.term_id)
    elsif 'category' == taxonomy

      # Filters the category link.
      termlink = apply_filters('category_link', termlink, term.term_id)
    end

    # Filters the term link.
    apply_filters( 'term_link', termlink, term, taxonomy )
  end

  # TODO the_taxonomies, get_the_taxonomies, get_post_taxonomies, is_object_in_term

  # Determine if the given object type is associated with the given taxonomy.
  #
  # @param [string] object_type Object type string.
  # @param [string] taxonomy    Single taxonomy name.
  # @return [bool] True if object is associated with the taxonomy, otherwise false.
  def is_object_in_taxonomy(object_type, taxonomy)
    taxonomies = get_object_taxonomies(object_type)
    return false if taxonomies.blank?
    taxonomies.include? taxonomy
  end

  # Get an array of ancestor IDs for a given object.
  #
  # @param [int]    object_id     Optional. The ID of the object. Default 0.
  # @param [string] object_type   Optional. The type of object for which we'll be retrieving
  #                               ancestors. Accepts a post type or a taxonomy name. Default empty.
  # @param [string] resource_type Optional. Type of resource $object_type is. Accepts 'post_type'
  #                               or 'taxonomy'. Default empty.
  # @return [array] An array of ancestors from lowest to highest in the hierarchy.
  def get_ancestors(object_id = 0, object_type = '', resource_type = '')
    object_id = object_id.to_i

    ancestors = []

    if object_id.blank?
      # This filter is documented in wp-includes/taxonomy.php
      return apply_filters( 'get_ancestors', ancestors, object_id, object_type, resource_type)
    end

    if !resource_type
      if is_taxonomy_hierarchical(object_type)
        resource_type = 'taxonomy'
      elsif post_type_exists(object_type)
        resource_type = 'post_type'
      end
    end

    if 'taxonomy' == resource_type
      term = get_term(object_id, object_type)
      # TODO continue
      #	while ( ! is_wp_error( $term ) && ! empty( $term->parent ) && ! in_array( $term->parent, $ancestors ) ) {
      #		ancestors[] = (int) $term->parent;
      #		term        = get_term(term.parent, object_type)
      #	}
    elsif 'post_type' == resource_type
      ancestors = get_post_ancestors(object_id)
    end

    # Filters a given object's ancestors.
    #
    # @param [array]  ancestors     An array of object ancestors.
    # @param [int]    object_id     Object ID.
    # @param [string] object_type   Type of object.
    # @param [string] resource_type Type of resource $object_type is.
    apply_filters('get_ancestors', ancestors, object_id, object_type, resource_type)
  end

  # TODO wp_get_term_taxonomy_parent_id, wp_check_term_hierarchy_for_loops, is_taxonomy_viewable, wp_cache_set_terms_last_changed, wp_check_term_meta_support_prefilter


end