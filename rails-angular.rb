# No turbo links
gsub_file "Gemfile", /^gem\s+["']turbolinks["'].*$/,''

# We'll use bower for our frontend assets
gem  'bower-rails'

gem 'sass', '3.2.19' 
gem_group :test, :development do
  gem "rspec-rails", "~> 2.0"
  gem "factory_girl_rails", "~> 4.0"
  gem "capybara"
  gem "database_cleaner"
  gem "selenium-webdriver"
end

# Remove tests directory as we're using specs
inside('.') do 
  run "rm -r test/"
end

# We'll use the asset system to serve templates
inside('app/assets/') do 
  run "mkdir templates"
end

after_bundle do

  # Setup bower
  inside('.') do
    run 'touch Bowerfile' 
    inject_into_file 'Bowerfile', after: '' do
<<-'CONT'
asset 'angular'
asset 'bootstrap-sass-official'
asset 'jasmine'
asset 'angular-mocks'

CONT
    end
  end
  rake "bower:install"
  
  route "root 'home#index'"
  generate "controller", "Home index --no-assets --no-helper --test-framework=rspec"
 
  # add vendor/assets/bower_components to assets path
  application do
<<-'CONT'

    config.assets.paths << Rails.root.join("vendor","assets","bower_components")
    config.assets.paths << Rails.root.join("vendor","assets","bower_components","bootstrap-sass-official","assets","fonts")
    config.assets.precompile << %r(.*.(?:eot|svg|ttf|woff)$)

    # Make bootstrap fonts work
    config.assets.paths << Rails.root.join("vendor","assets","bower_components","bootstrap-sass-official","assets","fonts")

CONT
  end

  initializer "assets.rb" do 
<<-'CONT'
Rails.application.config.assets.version = '1.0'
Rails.application.config.assets.precompile += %w( bootstrap-sass-official/assets/fonts/bootstrap/glyphicons-halflings-regular.woff2 )

CONT
  end

  # Setup angular in our asset system
  inside('app/assets/javascripts/') do
    gsub_file "application.js", /^.*turbolinks.*$/,''
    inject_into_file 'application.js', after: '//= require jquery_ujs' do
      "
//= require angular/angular"
    end
    
    run 'touch ng-app.js' 
    inject_into_file 'ng-app.js', after: '' do
      "angular.module('com.example.app', []);"
    end
  end

  # Setup sass and bootstrap etc
  inside('app/assets/stylesheets/') do
    run 'touch application.css.scss' 
    run 'rm application.css' 
    inject_into_file 'application.css.scss', after: '' do
<<-'CONT'
@import "bootstrap-sass-official/assets/stylesheets/bootstrap-sprockets";
@import "bootstrap-sass-official/assets/stylesheets/bootstrap";

CONT
    end
  end


  inside('app/views/home') do
    run 'rm index.html.erb' 
    run 'touch index.html.erb' 
    inject_into_file 'index.html.erb', after: '' do
<<-'CONT'
<div class="container-fluid" ng-app="com.example.app">
  <div class="panel panel-success">
    <div class="panel-heading">
      <h1 ng-if="name">Hello, {{name}}</h1>
    </div>
    <div class="panel-body">
      <form class="form-inline">
        <div class="form-group">
          <input class="form-control" type="text" placeholder="Enter your name" autofocus ng-model="name">
        </div>
      </form>
    </div>
  </div>
</div>

CONT
    end
  end

  # Setup git
  git :init
  git add: '.'
  git commit: "-a -m 'Initial commit'"
end
