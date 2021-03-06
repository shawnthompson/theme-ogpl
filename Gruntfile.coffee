#global module:false
module.exports = (grunt) ->

	# Default task.
	@registerTask(
		"default"
		"Default task, that runs the production build"
		[
			"dist"
		]
	)

	@registerTask(
		"travis"
		"Task run by the Travis-CI build"
		[
			"dist"
		]
	)

	@registerTask(
		"dist"
		"Produces the production files"
		[
			"checkDependencies"
			"build"
			"assets-dist"
			"assemble"
			"htmlmin"
			"useMinAssets"
		]
	)

	#Alternate External tasks
	@registerTask(
		"debug"
		"Produces unminified files"
		[
			"build"
			"assemble:demos"
			"assemble:theme"
		]
	)

	@registerTask(
		"build"
		"Produces unminified files"
		[
			"clean:dist"
			"copy:wetboew"
			"assets"
			"css"
			"js"
		]
	)

	@registerTask(
		"init"
		"Only needed when the repo is first cloned"
		[
			"install-dependencies"
			"hub"
		]
	)

	@registerTask(
		"deploy"
		"Build and deploy artifacts to wet-boew-dist"
		->
			if process.env.TRAVIS_PULL_REQUEST is "false" and process.env.DIST_REPO isnt `undefined` and ( process.env.TRAVIS_TAG isnt "" or process.env.TRAVIS_BRANCH is "master" )
				grunt.task.run [
					"copy:deploy"
					"gh-pages:travis"
					"gh-pages:travis_cdn"
					"wb-update-examples"
				]
	)

	@registerTask(
		"server"
		"Run the Connect web server for local repo"
		[
			"connect:server:keepalive"
		]
	)

	@registerTask(
		"css"
		"INTERNAL: Compiles Sass and vendor prefixes the result"
		[
			"sass"
			"autoprefixer"
			"usebanner:css"
			"cssmin"
			"cssmin_ie8_clean"
		]
	)

	@registerTask(
		"assets-dist"
		"INTERNAL: Process non-CSS/JS assets to dist"
		[
			"copy:wetboew_demo_min"
		]
	)

	@registerTask(
		"assets"
		"INTERNAL: Process non-CSS/JS assets to dist"
		[
			"copy:assets"
			"copy:wetboew_demo"
		]
	)

	@registerTask(
		"js"
		"INTERNAL: Brings in the custom JavaScripts."
		[
			"copy:js"
			"uglify"
		]
	)

	@registerTask(
		"useMinAssets"
		"Replace unmin refrences with the min paths for HTML files"
		() ->
			htmlFiles = grunt.file.expand(
				"dist/**/*.html"
				"!dist/unmin/**/*.html"
			);

			htmlFiles.forEach(
				( file ) ->
					contents = grunt.file.read( file )
					contents = contents.replace( /\.\.\/(wet\-boew|theme\-ogpl)/g, "$1" )
					contents = contents.replace( /\"(?!https:)([^\"]*)?\.(js|css)\"/g, "\"$1.min.$2\"" )

					grunt.file.write(file, contents);
			);
	)

	@initConfig

		# Metadata.
		pkg: @file.readJSON("package.json")
		themeDist: "dist/<%= pkg.name %>"
		jqueryVersion: grunt.file.readJSON("lib/jquery/bower.json")
		jqueryOldIEVersion: grunt.file.readJSON("lib/jquery-oldIE/bower.json")
		banner: "/*!\n * Web Experience Toolkit (WET) / Boîte à outils de l'expérience Web (BOEW)\n * wet-boew.github.io/wet-boew/License-en.html / wet-boew.github.io/wet-boew/Licence-fr.html\n" +
				" * v<%= pkg.version %> - " + "<%= grunt.template.today('yyyy-mm-dd') %>\n *\n */"
		locales: grunt.file.expand(
			cwd: "site/data/i18n"
			, "*.json").map((src) ->
				src.replace ".json", ""
		)
		deployBranch: "<%= pkg.name %>"

		checkDependencies:
			all:
				options:
					npmInstall: false
		clean:
			dist: [ "dist"]

		copy:
			wetboew:
				expand: true
				cwd: "lib/wet-boew/dist"
				src: [
					"wet-boew/**/*.*"
					"**/ajax/**/*.*"
				]
				dest: "dist"
			wetboew_demo:
				expand: true
				cwd: "lib/wet-boew/dist/unmin"
				src: [
					"demos/**/*.*"
					"docs/**/*.*"
					"!**/*.html"
					"demos/**/ajax/*.html"
				]
				dest: "dist/unmin"
			wetboew_demo_min:
				expand: true
				cwd: "lib/wet-boew/dist"
				src: "<%= copy.wetboew_demo.src %>"
				dest: "dist"
			assets:
				expand: true
				cwd: "src/assets"
				src: "**/*.*"
				dest: "<%= themeDist %>/assets"
			js:
				expand: true
				cwd: "src"
				src: "**/*.js"
				dest: "<%= themeDist %>/js"
			deploy:
				files: [
					{
						src: [
							"*.txt"
							"README.md"
						]
						dest: "dist"
						expand: true
					}

					{
						src: "*.txt"
						dest: "<%= themeDist %>"
						expand: true
					}

					#Backwards compatibility.
					#TODO: Remove in v4.1
					{
						cwd: "<%= themeDist %>"
						src: "**/*.*"
						dest: "dist"
						expand: true
					}
					{
						cwd: "dist/wet-boew"
						src: "**/*.*"
						dest: "dist"
						expand: true
					}
				]

				#Backwards compatibility.
				#TODO: Remove in v4.1
				options:
					noProcess: [
						'**/*.{png,gif,jpg,ico,ttf,eot,otf,woff,svg,swf}'
					]
					process: (content, filepath) ->
						if filepath.match(/\.css/)
							return content.replace(/\.\.\/\.\.\/wet-boew\/(assets|fonts)/g, '../$1')
						content

		sass:
			all:
				expand: true
				cwd: "src"
				src: "*.scss"
				dest: "<%= themeDist %>/css"
				ext: ".css"

		autoprefixer:
			options:
				browsers: [
					"last 2 versions"
					"android >= 2.3"
					"bb >= 7"
					"ff >= 17"
					"ie >= 8"
					"ios 5"
					"opera 12.1"
				]
			modern:
				cwd: "<%= themeDist %>/css"
				src: [
					"*.css"
					"!ie8*.css"
				]
				dest: "<%= themeDist %>/css"
				expand: true
			oldIE:
				options:
					browsers: [
						"ie 8"
					]
				cwd: "<%= themeDist %>/css"
				src: [
					"ie8*.css"
				]
				dest: "<%= themeDist %>/css"
				expand: true

		usebanner:
			css:
				options:
					banner: "@charset \"utf-8\";\n<%= banner %>"
				files:
					src: "<%= themeDist %>/css/*.*"

		cssmin:
			theme:
				expand: true
				cwd: "<%= themeDist %>/css/"
				src: "*.css"
				ext: ".min.css"
				dest: "<%= themeDist %>/css"

		cssmin_ie8_clean:
			min:
				expand: true
				cwd: "<%= themeDist %>/css"
				src: [
					"**/ie8*.min.css"
				]
				dest: "<%= themeDist %>/css"

		# Minify
		uglify:
			dist:
				options:
					banner: "<%= banner %>"
				expand: true
				cwd: "<%= themeDist %>/"
				src: "**/*.js"
				dest: "<%= themeDist %>/"
				ext: ".min.js"

		assemble:
			options:
				prettify:
					indent: 2
				marked:
					sanitize: false
				production: false
				data: [
					"lib/wet-boew/site/data/**/*.{yml,json}"
					"site/data/**/*.{yml,json}"
				]
				helpers: [
					"lib/wet-boew/site/helpers/helper{,s}-*.js"
					"site/helpers/helper{,s}-*.js"
				]
				partials: [
					"lib/wet-boew/site/includes/**/*.hbs"
					"site/includes/**/*.hbs"
				]
				layoutdir: "site/layouts"
				layout: "default.hbs"
				environment:
					jqueryVersion: "<%= jqueryVersion.version %>"
					jqueryOldIEVersion: "<%= jqueryOldIEVersion.version %>"
				assets: "dist/unmin"

			theme:
				options:
					flatten: true,
					plugins: ["assemble-contrib-i18n"]
					i18n:
						languages: "<%= locales %>"
						templates: [
							"site/pages/*.hbs"
							"!site/pages/splashpage*.hbs"
							"!site/pages/index*.hbs"
							"!site/pages/404*.hbs"
							"!site/pages/servermessage-*.hbs"
						]
				dest: "dist/unmin/"
				src: "!*.*"

			demos:
				files: [
						#site
						expand: true
						cwd: "site/pages"
						src: [
							"**/*.hbs"
							"!*.hbs"
							"splashpage*.hbs"
							"index*.hbs"
							"404*.hbs"
							"servermessage-*.hbs"
						]
						dest: "dist/unmin"
					,
						#plugins
						expand: true
						cwd: "lib/wet-boew/site/pages/demos"
						src: [
							"**/*.hbs"
						]
						dest: "dist/unmin/demos"
					,
						expand: true
						cwd: "lib/wet-boew/src/plugins"
						src: [
							"**/*.hbs"
						]
						dest: "dist/unmin/demos"
					,
						expand: true
						cwd: "lib/wet-boew/src/polyfills"
						src: "**/*.hbs"
						dest: "dist/unmin/demos"
					,
						expand: true
						cwd: "lib/wet-boew/src/other"
						src: "**/*.hbs"
						dest: "dist/unmin/demos"
				]

		htmlmin:
			options:
				collapseWhitespace: true
				preserveLineBreaks: true
				preventAttributesEscaping: true
			all:
				cwd: "dist/unmin"
				src: [
					"**/*.html"
				]
				dest: "dist"
				expand: true

		hub:
			"wet-boew":
				src: [
					"lib/wet-boew/Gruntfile.coffee"
				]
				tasks: [
					"dist"
				]

		"install-dependencies":
			options:
				cwd: "lib/wet-boew"
				failOnError: false
				isDevelopment: true

		connect:
			options:
				port: 8000

			server:
				options:
					base: "dist"
					middleware: (connect, options, middlewares) ->
						middlewares.unshift(connect.compress(
							filter: (req, res) ->
								/json|text|javascript|dart|image\/svg\+xml|application\/x-font-ttf|application\/vnd\.ms-opentype|application\/vnd\.ms-fontobject/.test(res.getHeader('Content-Type'))
						))
						middlewares

		"gh-pages":
			options:
				clone: "themes-dist"
				base: "dist"

			travis:
				options:
					repo: process.env.DIST_REPO
					branch: "<%= deployBranch %>"
					message: ((
						if process.env.TRAVIS_TAG
							"Production files for the " + process.env.TRAVIS_TAG + " maintenance release"
						else
							"Travis build " + process.env.TRAVIS_BUILD_NUMBER
					))
					silent: true,
					tag: ((
						if process.env.TRAVIS_TAG then process.env.TRAVIS_TAG + "-" + "<%= pkg.name.toLowerCase() %>" else false
					))
				src: [
					"**/*.*"
				]

			travis_cdn:
				options:
					repo: process.env.CDN_REPO
					branch: "<%= deployBranch %>"
					clone: "themes-cdn"
					base: "<%= themeDist %>"
					message: ((
						if process.env.TRAVIS_TAG
							"CDN files for the " + process.env.TRAVIS_TAG + " maintenance release"
						else
							"Travis build " + process.env.TRAVIS_BUILD_NUMBER
					))
					silent: true,
					tag: ((
						if process.env.TRAVIS_TAG then process.env.TRAVIS_TAG + "-" + "<%= pkg.name.toLowerCase() %>" else false
					))
				src: [
					"**/*.*"
				]

		"wb-update-examples":
			travis:
				options:
					repo: process.env.DEMOS_REPO
					branch: process.env.DEMOS_BRANCH
					message: "<%= grunt.config('gh-pages.travis.options.message') %>"
					silent: true

	# These plugins provide necessary tasks.
	@loadNpmTasks "assemble"
	@loadNpmTasks "grunt-autoprefixer"
	@loadNpmTasks "grunt-banner"
	@loadNpmTasks "grunt-check-dependencies"
	@loadNpmTasks "grunt-contrib-clean"
	@loadNpmTasks "grunt-contrib-connect"
	@loadNpmTasks "grunt-contrib-copy"
	@loadNpmTasks "grunt-contrib-cssmin"
	@loadNpmTasks "grunt-contrib-jshint"
	@loadNpmTasks "grunt-contrib-htmlmin"
	@loadNpmTasks "grunt-contrib-uglify"
	@loadNpmTasks "grunt-contrib-watch"
	@loadNpmTasks "grunt-cssmin-ie8-clean"
	@loadNpmTasks "grunt-gh-pages"
	@loadNpmTasks "grunt-hub"
	@loadNpmTasks "grunt-install-dependencies"
	@loadNpmTasks "grunt-sass"
	@loadNpmTasks "grunt-wet-boew-postbuild"

	require( "time-grunt" )( grunt )
	@
