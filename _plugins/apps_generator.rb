module AppsGenerator
  class Generator < Jekyll::Generator
    safe true
    priority :high

    def generate(site)
      # Get apps data from _data/apps.yml
      apps_data = site.data['apps']
      return unless apps_data

      apps_data.each do |app|
        app_id = app['id']
        html_file_path = File.join(site.source, 'apps', app_id, 'index.html')

        # Check if HTML file exists
        next unless File.exist?(html_file_path)

        # Read the HTML content
        html_content = File.read(html_file_path)

        # Update asset paths to use app-specific namespace
        # Handle absolute paths
        html_content = html_content.gsub(/\/apps\/assets\//, "/assets/#{app_id}/")
        html_content = html_content.gsub(/\{\{\s*'\/apps\/assets\/([^']+)'\s*\|\s*relative_url\s*\}\}/, "/assets/#{app_id}/\\1")

        # Handle relative paths (src="assets/" and href="assets/")
        html_content = html_content.gsub(/src="assets\//, "src=\"/assets/#{app_id}/")
        html_content = html_content.gsub(/href="assets\//, "href=\"/assets/#{app_id}/")

        # Create a page without file using Jekyll::PageWithoutAFile
        page = Jekyll::PageWithoutAFile.new(site, site.source, '', "#{app_id}.html")

        # Set the content and metadata
        page.content = html_content
        page.data.merge!({
          'layout' => nil,
          'title' => app['title'],
          'description' => app['description'],
          'icon' => app['icon'],
          'permalink' => "/#{app_id}/"
        })

        # Add to site pages
        site.pages << page

        # Copy assets if they exist
        assets_dir = File.join(site.source, 'apps', app_id, 'assets')
        if Dir.exist?(assets_dir)
          # App has its own assets directory
          Dir.glob("#{assets_dir}/**/*").each do |asset_file|
            next unless File.file?(asset_file)

            # Get relative path from assets directory
            relative_path = asset_file.sub("#{assets_dir}/", '')

            # Create static file that will be copied to /assets/app_id/
            static_file = Jekyll::StaticFile.new(site, assets_dir, '', relative_path)
            static_file.instance_variable_set(:@relative_path, "/assets/#{app_id}/#{relative_path}")

            site.static_files << static_file
          end
        else
          # App uses shared assets, copy from apps/assets/
          shared_assets_dir = File.join(site.source, 'apps', 'assets')
          if Dir.exist?(shared_assets_dir)
            Dir.glob("#{shared_assets_dir}/**/*").each do |asset_file|
              next unless File.file?(asset_file)

              # Get relative path from shared assets directory
              relative_path = asset_file.sub("#{shared_assets_dir}/", '')

              # Create static file that will be copied to /assets/app_id/
              static_file = Jekyll::StaticFile.new(site, shared_assets_dir, '', relative_path)
              static_file.instance_variable_set(:@relative_path, "/assets/#{app_id}/#{relative_path}")

              site.static_files << static_file
            end
          end
        end
      end
    end
  end
end