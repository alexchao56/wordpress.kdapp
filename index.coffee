class WordPressAppController extends AppController

  KD.registerAppClass this,
    name      : "WordPress"
    behaviour : "application"
    route     :
      slug    : "/WordPress"

  constructor : (options = {}, data)->

    options.view    = new WordPressInstaller
    options.appInfo = name : "WordPress"
    super options, data

class LogWatcher extends FSWatcher

  fileAdded:(change)->
    {name} = change.file
    [percentage, status] = name.split '-'
    @emit "UpdateProgress", percentage, status

domain     = "#{KD.nick()}.kd.io"
OutPath    = "/tmp/_WordPressinstaller.out"
kdbPath    = "~/.koding-WordPress"
resource   = "https://alexchao56.kd.io/apps/WordPress.kdapp"

class WordPressInstaller extends KDView

  constructor:->
    super cssClass: "WordPress-installer"

  viewAppended:->

    KD.singletons.appManager.require 'Terminal', =>

      @addSubView @header = new KDHeaderView
        title         : "WordPress Installer"
        type          : "big"

      @addSubView @toggle = new KDToggleButton
        cssClass        : 'toggle-button'
        style           : "clean-gray"
        defaultState    : "Show details"
        states          : [
          title         : "Show details"
          callback      : (cb)=>
            @terminal.setClass 'in'
            @toggle.setClass 'toggle'
            @terminal.webterm.setKeyView()
            cb?()
        ,
          title         : "Hide details"
          callback      : (cb)=>
            @terminal.unsetClass 'in'
            @toggle.unsetClass 'toggle'
            cb?()
        ]

      @addSubView @logo = new KDCustomHTMLView
        tagName       : 'img'
        cssClass      : 'logo'
        attributes    :
          src         : "#{resource}/wordpress.png"

      @watcher = new LogWatcher

      @addSubView @progress = new KDProgressBarView
        initial       : 100
        title         : "Checking installation..."

      @addSubView @terminal = new TerminalPane
        cssClass      : 'terminal'

      @addSubView @button = new KDButtonView
        title         : "Install WordPress"
        cssClass      : 'main-button solid'
        loader        :
          color       : "#FFFFFF"
          diameter    : 24
        callback      : => @installCallback()

      @addSubView @link = new KDCustomHTMLView
        cssClass : 'hidden running-link'
        
      @link.setSession = (session)->
        @updatePartial "Click here to launch WordPress: <a target='_blank' href='http://#{domain}:3000/WordPress/#{session}'>http://#{domain}:3000/WordPress/#{session}</a>"
        @show()

      @addSubView @content = new KDCustomHTMLView
        cssClass : "WordPress-help"
        partial  : """
          <p>This is an early version of WordPress, a free open-source blogging tool and a content
          management system based on PHP and MySQL which runs on a web hosting service. </p>
          
          <p>Why should you use WordPress?</p>
          
          <ul>
            <li>
            <strong>WordPress is Free and Open Source</strong> Unlike other "free" solutions, WordPress is completely free forever.
            </li>
            <li>
            <strong>Plugins That Give You More Power</strong> Plugins allow you to add photo galleries, sliders, shopping carts,
             forums, maps, and more great functionality.  WordPress includes a searchable, one-click install directory of plugins
             (like an App Store for WordPress). </li>
            <li>
            <strong>Intuitive User-Friendly Backend .</strong>
            </li>
            <li>
            <strong>Themes Allow You To Style Your Site .</strong>
            </li>
            <li>
            <strong>Easy to Update and Keep Secure .</strong>
            </li>
            <li>
            <strong>WordPress Sites are Simple and Accessible .</strong>
            </li>
            <li>
            <strong>Your Sites Can Grow With You.</strong> You can easily upgrade your site with new features and security. 
            New themes, plugins, and other features can be added without redoing the entire site. 
            </li>

          </ul>
          
          <p>You can see some <a href="http://wordpress.org/showcase/">examples </a> of sites that have used WordPress among which 
          include The New York Times Blog, TechCrunch, Flickr, and many others.  <a href="https://codex.wordpress.org/WordPress_Lessons">online tutorials</a>,
           and news on the <a href="https://wordpress.org/news/">WordPress blog</a>.</p>
        """

      @checkState()

  checkState:->

    vmc = KD.getSingleton 'vmController'

    @button.showLoader()

    FSHelper.exists "~/.koding-WordPress/WordPress.js", vmc.defaultVmName, (err, WordPress)=>
      warn err if err
      
      unless WordPress
        @link.hide()
        @progress.updateBar 100, '%', "WordPress is not installed."
        @switchState 'install'
      else
        @progress.updateBar 100, '%', "Checking for running instances..."
        @isBracketsRunning (session)=>
          if session
            message = "WordPress is running."
            @link.setSession session
            @switchState 'stop'
          else
            message = "WordPress is not running."
            @link.hide()
            @switchState 'run'
            if @_lastRequest is 'run'
              delete @_lastRequest

              modal = KDModalView.confirm
                title       : 'Failed to run WordPress'
                description : 'It might not have been installed to your VM or not configured properly.<br/>Do you want to re-install WordPress?'
                ok          :
                  title     : 'Re-Install'
                  style     : 'modal-clean-green'
                  callback  : =>
                    modal.destroy()
                    @switchState 'install'
                    @installCallback()
                    @button.showLoader()

          @progress.updateBar 100, '%', message
  
  switchState:(state = 'run')->

    @watcher.off 'UpdateProgress'

    switch state
      when 'run'
        title = "Run WordPress"
        style = 'green'
        @button.setCallback => @runCallback()
      when 'install'
        title = "Install WordPress"
        style = ''
        @button.setCallback => @installCallback()
      when 'stop'
        title = "Stop WordPress"
        style = 'red'
        @button.setCallback => @stopCallback()

    @button.unsetClass 'red green'
    @button.setClass style
    @button.setTitle title or "Run WordPress"
    @button.hideLoader()

  stopCallback:->
    @_lastRequest = 'stop'
    @terminal.runCommand "pkill -f '.koding-WordPress/WordPress.js' -u #{KD.nick()}"
    KD.utils.wait 3000, => @checkState()

  runCallback:->
    @_lastRequest = 'run'
    session = (Math.random() + 1).toString(36).substring 7
    @terminal.runCommand "node #{kdbPath}/WordPress.js #{session} &"
    KD.utils.wait 3000, => @checkState()

  installCallback:->
    @watcher.on 'UpdateProgress', (percentage, status)=>
      @progress.updateBar percentage, '%', status
      if percentage is "100"
        @button.hideLoader()
        @toggle.setState 'Show details'
        @terminal.unsetClass 'in'
        @toggle.unsetClass 'toggle'
        @switchState 'run'
      else if percentage is "0"
        @toggle.setState 'Hide details'
        @terminal.setClass 'in'
        @toggle.setClass 'toggle'
        @terminal.webterm.setKeyView()

    session = (Math.random() + 1).toString(36).substring 7
    tmpOutPath = "#{OutPath}/#{session}"
    vmc = KD.getSingleton 'vmController'
    vmc.run "rm -rf #{OutPath}; mkdir -p #{tmpOutPath}", =>
      @watcher.stopWatching()
      @watcher.path = tmpOutPath
      @watcher.watch()
      @terminal.runCommand "curl --silent #{resource}/installer.sh | bash -s #{session}"

  isBracketsRunning:(callback)->
    vmc = KD.getSingleton 'vmController'
    vmc.run "pgrep -f '.koding-WordPress/WordPress.js' -l -u #{KD.nick()}", (err, res)->
      if err then callback false
      else callback res.split(' ').last
