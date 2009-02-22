# Note that in all defined classes I'm ignoring values I don't happen to care
# about. If you care about them, please feel free to add support for them,
# which should not be difficult.
#
# Plural attribute names will be treated as arrays unless the element name
# in the xml document is already plural. (Convention seems to be to label
# repeating elements in the singular.)
#
# If an attribute should be a non-trivial datatype, define the mapping from
# the fully namespaced attribute name to the class you wish to use in the
# class method #types.
#
# Define which namespaces you support in the class method #namespaces. Any
# elements defined in other namespaces are automatically ignored.
module RubyPicasa
  class PhotoUrl < Objectify::ElementParser
    attr_accessor :url, :height, :width
  end


  class User < Objectify::DocumentParser
    attributes :id,
      :updated,
      :title,
      :total_results, # represents total number of albums
      :start_index,
      :items_per_page,
      :thumbnail
    has_many :links, Objectify::Atom::Link, 'link'
    has_many :entries, :Album, 'entry'
    has_one :content, PhotoUrl, 'media:content'
    has_many :thumbnails, PhotoUrl, 'media:thumbnail'
    namespaces %w[openSearch gphoto]
    flatten 'media:group'
  end


  class Album < Objectify::DocumentParser
    attributes :id,
      :published,
      :updated,
      :title,
      :summary,
      :rights,
      :gphoto_id,
      :name,
      :access,
      :numphotos, # number of pictures in this album
      :total_results, # number of pictures matching this 'search'
      :start_index,
      :items_per_page,
      :allow_downloads
    has_many :links, Objectify::Atom::Link, 'link'
    has_many :entries, :Photo, 'entry'
    has_one :content, PhotoUrl, 'media:content'
    has_many :thumbnails, PhotoUrl, 'media:thumbnail'
    flatten 'media:group'
    namespaces %w[openSearch gphoto media]
  end


  class Photo < Objectify::DocumentParser
    attributes :id,
      :published,
      :updated,
      :title,
      :summary,
      :gphoto_id,
      :version, # can use to determine if need to update...
      :position,
      :albumid, # useful from the recently updated feed for instance.
      :width,
      :height,
      :description,
      :keywords
    has_many :links, Objectify::Atom::Link, 'link'
    has_one :content, PhotoUrl, 'media:content'
    has_many :thumbnails, PhotoUrl, 'media:thumbnail'
    namespaces %w[gphoto media]
    flatten 'media:group'
  end


  class Search < Album
    def initialize(q, start_index = 1, max_results = 10)
      raise "Incorect query type." unless q.is_a? String
      @q = q
      @start_index = start_index
      @max_results = max_results
      request = "http://picasaweb.google.com/data/feed/api/all?q=#{ CGI.escape(q.to_s) }&start-index=#{ CGI.escape(start_index.to_s) }&max-results=#{ CGI.escape(max_results.to_s) }"
      xml = open(request).read
      super(xml)
    end

    def next_results
      Search.new(@q, @start_index + @max_results, @max_results)
    end
  end
end
