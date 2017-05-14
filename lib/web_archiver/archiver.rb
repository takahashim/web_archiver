require 'uri'
require 'fileutils'
require 'logger'
require 'httpclient'

module WebArchiver
  class Archiver

    # @params [URI] uri 取得するHTMLのURL
    # @params [String] base_path 起点となるパス。これより下のディレクトリ・ファイルのみ取得する
    #
    def initialize(root_dir, base_path)
      @root_dir = root_dir
      @base_path = base_path

      @log = Logger.new(STDERR,datetime_format: '%Y-%m-%d %H:%M:%S')
      @conn = HTTPClient.new
    end

    # 指定されたディレクトリをdocument_rootとして再帰的にアーカイブする
    #
    # @params [WebArchiver::Document] doc
    #
    def archive(doc)
      source = http_get(doc.uri)
      if source
        doc.source = source
        save_resources(doc)
        archive_links(doc)
      end
    end

    # コンテンツ内のリンクをアーカイブする
    #
    # @params [WebArchiver::Document] doc
    #
    def archive_links(doc)
      doc.internal_links.each do |new_uri|
        save_path = canonicalize_path(@root_dir, new_uri)
        if new_uri.path.include?(@base_path) &&
           !File.exist?(save_path)
          @log.debug("archive DO"){[new_uri]}
          extname = File.extname(new_uri.path)
          if extname == "" || extname == ".html"
            new_doc = WebArchiver::Document.new(new_uri)
            archive(new_doc)
          else
            download_resource(new_uri, doc)
          end
        end
      end
    end

    # GETでコンテンツを取得する
    #
    # @params [URI] remote_uri
    # @return [String] urlから取得したコンテンツ
    # @return [nil]  取得に失敗した場合
    def http_get(remote_uri)
      @log.info("http_get"){remote_uri}
      resp = @conn.get(remote_uri, :follow_redirect => true)
      if HTTP::Status.successful?(resp.code)
        resp.body
      else
        @log.error("http_get"){[resp, remote_uri]}
        nil
      end
    end

    # 各リソースをダウンロードして保存する
    #
    # @params [WebArchiver::Document] doc
    def save_resources(doc)
      doc.internal_images.each do |uri|
        download_resource(uri, doc)
      end
      doc.internal_javascripts.each do |uri|
        download_resource(uri, doc)
      end
      doc.internal_csses.each do |uri|
        download_resource(uri, doc)
      end

      path = canonicalize_path(@root_dir, doc.uri)
      save_data(path, doc.to_html)
    end

    # 指定されたpathにデータを保存する
    #
    # @params [String] path
    # @params [String] data
    #
    def save_data(path, data)
      FileUtils.mkdir_p(File.dirname(path))
      IO.binwrite(path, data)
    end

    # 指定したURIのファイルをダウンロードして保存する
    #
    # @params [URI] target_uri
    #
    def download_resource(target_uri, doc)
      path = canonicalize_path(@root_dir, target_uri)
      # すでに取得済みの場合は無視
      if File.exist?(path)
        return
      end
      data = http_get(target_uri)
      if data
        @log.debug("download OK"){[target_uri, path]}
        save_data(path, data)
        # CSSの場合はCSS内のファイルをダウンロード
        if File.extname(target_uri.path) == ".css"
          data.scan(/url\((.*)\)/) do |matched|
            matched.each do |url_in_css|
              url_in_css.gsub!(/"/, '')
              r_uri = target_uri.merge(url_in_css)
              download_resource(r_uri, doc)
            end
          end
        end
      end
    end

    # URIを元にpathを正規化する
    #
    # @params [String] root_dir  document_root directory
    # @params [URI] target_uri
    # @return [String] save_path
    #
    def canonicalize_path(root_dir, target_uri)
      path = target_uri.path
      extname = File.extname(path)
      if extname != ""
        save_path = File.join(root_dir, path)
      else
        save_path = File.join(root_dir, path, 'index.html')
      end
      save_path
    end
  end
end
