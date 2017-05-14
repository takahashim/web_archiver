require 'uri'
require 'nokogiri'

module WebArchiver
  class Document

    attr_reader :uri
    attr_reader :path

    # @params [URI] uri 取得するHTMLのURL
    #
    def initialize(uri)
      @uri = uri
      @path = uri.path
    end

    def source=(src)
      @src = src
      @contents = Nokogiri::HTML(src)
    end

    # コンテンツ内のリンクを取得する
    #
    # @return [Hash] URL文字列がキー、:not_yetが値のハッシュを返す
    def links
      url_list = @contents.xpath('//a[@href]').map{|elem| elem[:href]}.uniq
      url_list.map{|url| @uri.merge(url)} || []
    end

    def internal_links
      links.select{|uri| uri.host == @uri.host}
    end

    def images
      ## XXX HTMLのコーディングミスでエラーになるのがあるので追加
      @contents.xpath('//img[@src]').map{|elem| @uri.merge(elem[:src].gsub(' ',''))}
    end

    def internal_images
      images.select{|uri| uri.host == @uri.host}
    end

    def javascripts
      @contents.xpath('//script[@src]').map{|elem| @uri.merge(elem[:src])}
    end

    def internal_javascripts
      javascripts.select{|uri| uri.host == @uri.host}
    end

    def csses
      @contents.xpath('//link[@rel="stylesheet"]').map{|elem| @uri.merge(elem[:href])}
    end

    def internal_csses
      csses.select{|uri| uri.host == @uri.host}
    end

    def to_html
      @contents.to_html
    end
  end
end
