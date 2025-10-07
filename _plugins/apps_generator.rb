module AppsGenerator
  class Generator < Jekyll::Generator
    safe true
    priority :high

    def generate(site)
      # Get apps data from _data/apps.yml
      apps_data = site.data['apps']
      return unless apps_data

      apps_data.each do |app|
        # Only process visible apps
        next unless app['visible']

        app_id = app['id']
        html_file_path = File.join(site.source, 'apps', app_id, 'index.html')

        # Check if HTML file exists
        next unless File.exist?(html_file_path)

        # Read the HTML content
        html_content = File.read(html_file_path)

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
      end
    end
  end
end