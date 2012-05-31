package com.livestation.plugins.googleanalytics {

  /////////////////////////////////////////////////////////////////////////////////////////
  // DEPENDENCIES
  ////////////////////////////////////////////////////////////////////////////////////////

  import com.longtailvideo.jwplayer.player.*;
  import com.longtailvideo.jwplayer.events.*;
  import com.longtailvideo.jwplayer.model.*;
  import com.longtailvideo.jwplayer.plugins.IPlugin;
  import com.longtailvideo.jwplayer.plugins.PluginConfig;
  import com.longtailvideo.jwplayer.utils.Configger;
  import com.longtailvideo.jwplayer.utils.Logger;

  import com.google.analytics.AnalyticsTracker;
  import com.google.analytics.GATracker;
  import com.google.analytics.core.DomainNameMode;
  import com.google.analytics.core.Domain;
  
  import flash.events.*;
  import flash.display.MovieClip;
  import flash.external.ExternalInterface;
  import flash.utils.*;
  import flash.utils.Timer;
  
  import com.livestation.plugins.googleanalytics.VideoEvent;
  import com.livestation.plugins.googleanalytics.CategoryType;

  // * Watch Live Plugin; Just adds a button which links back to the live channel
  public class GoogleAnalytics extends MovieClip implements IPlugin {

    /////////////////////////////////////////////////////////////////////////////////////////
    // VARIABLE DEFINITION
    /////////////////////////////////////////////////////////////////////////////////////////

    private var _player:IPlayer;
    private var _config:PluginConfig;
    private var _tracker:AnalyticsTracker;
    private var _gaUA:String;
    private var _gaMode:String = "Bridge";
    private var _gaDebug:Boolean = false;
    private var _trackAdverts:Boolean = false;
    private var _categoryPrefix:String = "";
    private var _domain:String = ".livestation.com";
    private var _fullscreen:Boolean = false;
    private var _currentPosition:Number = 0;
    private var _volume:Number;
    private var _category:String;
    
    private var _label:String;
    private var _action:String;
    
    private var _timeWatched:int = 0;
    private var _lastPlayTime:int = 0;
    
    private var _startTime:int;
    private var _viewTimer:Timer;
    private var _channelViewTimerIntervals:Array = [
      10, // 10s
      20, // 30s (10s + 20s)
      30, // 1m (30s + 30s)
      60, // 2m (60s)
      60, // 3m .. 
      60, // 4m ..
      60, // 5m ..
      300 // 10m (300s - 5 min interval)
    ];
    
    private var _clipViewTimerIntervals:Array = [
      5,  // 5s
      5,  // 10s
      15, // 25s (15 sec interval)
    ];
    
    private var _currentViewTimerIntervalIndex:int = -1;
    
    
    private var ANALYTICS_INIT_ERROR:String = "Please supply account ID as googleanalytics.accountid in configuration";
    
    public static var LOGGER_TYPE:String = "LS-GOOGLEANALYTICS"
    
    public function GoogleAnalytics():void {}
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // INITIALIZATION
    /////////////////////////////////////////////////////////////////////////////////////////
     
    /** The initialize call is invoked by the player. **/
    public function initPlugin(player:IPlayer, cfg:PluginConfig):void {
      _player = player;
      _config = cfg;
      _fullscreen = _player.config.fullscreen;
      _volume = _player.config.volume;
      _startTime = 0;
      
      log("Started Google Analytics Plugin v2.0");
      
      initConfig();      
      initJavaScriptCallbacks();
      initGoogleAnalyticsTracker();
      initTimer();
    }
    
    // Set some private variables based on config options or defaults
    private function  initConfig():void{
      // Set some config options
      _gaUA = config['accountid'];
      _gaDebug = config['debug'] || false;
      _label = config['label'];
      _action = config['action'];
      _trackAdverts = config['trackadverts'] || false;
      _category = config["category"] || CategoryType.CHANNEL;
      
      if(config["mode"] !== undefined){
        _gaMode = config["mode"];
      }
      if(config["domain"] !== undefined){
        _domain = config['domain'];
      }
    }
    
    // Allow events from JavaScript to be received
    private  function initJavaScriptCallbacks():void{
      ExternalInterface.addCallback("sendToActionscript", callFromJavaScript);
    }
    
    // Initialize the Google Analytics tracking library
    private function initGoogleAnalyticsTracker():void{
      if(_gaUA != null){
        _tracker = new GATracker(this, _gaUA, _gaMode, _gaDebug);
        _tracker.setDomainName(_domain);
        initEvents();
      }else{
        log(ANALYTICS_INIT_ERROR);
      }
    }
    
    private function initEvents():void{
      // Player Events
      _player.addEventListener(PlayerEvent.JWPLAYER_READY, playerReady);
      _player.addEventListener(PlayerStateEvent.JWPLAYER_PLAYER_STATE, playerStateHandler);
      
      // Media Events
      _player.addEventListener(MediaEvent.JWPLAYER_MEDIA_TIME, mediaTime);
      _player.addEventListener(MediaEvent.JWPLAYER_MEDIA_COMPLETE, mediaComplete);
      _player.addEventListener(MediaEvent.JWPLAYER_MEDIA_VOLUME, mediaVolume);
      _player.addEventListener(MediaEvent.JWPLAYER_MEDIA_MUTE, mediaMute);
      _player.addEventListener(MediaEvent.JWPLAYER_MEDIA_ERROR, mediaError);
      _player.addEventListener(MediaEvent.JWPLAYER_MEDIA_SEEK, mediaSeek);

      // View Events
      _player.addEventListener(ViewEvent.JWPLAYER_VIEW_FULLSCREEN, viewFullscreen);
      _player.addEventListener(ViewEvent.JWPLAYER_VIEW_PLAY, viewPlay);
      
      // Media Events
      //_player.addEventListener(MediaEvent.JWPLAYER_MEDIA_LOADED, mediaLoaded);
      //_player.addEventListener(MediaEvent.JWPLAYER_MEDIA_META, mediaMeta);
      
      // Playlist Events
      //_player.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_LOADED, playlistLoaded);
      //_player.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_UPDATED, playlistUpdated);
      //_player.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_ITEM, playlistItem);
      
      // View Events      
      //_player.addEventListener(ViewEvent.JWPLAYER_VIEW_ITEM, viewItem);
      //_player.addEventListener(ViewEvent.JWPLAYER_VIEW_LOAD, viewLoad);
      //_player.addEventListener(ViewEvent.JWPLAYER_VIEW_NEXT, viewNext);
      //_player.addEventListener(ViewEvent.JWPLAYER_VIEW_PAUSE, viewPause);
      //_player.addEventListener(ViewEvent.JWPLAYER_VIEW_PREV, viewPrev);
      //_player.addEventListener(ViewEvent.JWPLAYER_VIEW_REDRAW, viewRedraw);
      //_player.addEventListener(ViewEvent.JWPLAYER_VIEW_SEEK, viewSeek);
      //_player.addEventListener(ViewEvent.JWPLAYER_VIEW_STOP, viewStop);
      //_player.addEventListener(ViewEvent.JWPLAYER_VIEW_VOLUME, viewVolume);      
      
    }    

    /////////////////////////////////////////////////////////////////////////////////////////
    // REQUIRED PLUGIN INTERFACE METHODS
    /////////////////////////////////////////////////////////////////////////////////////////

    // Player resize method
    public function resize(width:Number, height:Number):void {}
    
    // Config object
    public function get config():PluginConfig {
      return _player.config.pluginConfig('googleanalytics');
    }
    
    // ID of the plugin
    public function get id():String {
      return "googleanalytics";
    }
    


 
    /////////////////////////////////////////////////////////////////////////////////////////
    // ATTRIBUTE ACCESSORS
    /////////////////////////////////////////////////////////////////////////////////////////
    
    private function currentItem():PlaylistItem{
     return _player.playlist.currentItem;
    }
    
    private function currentAuthor():String{
      return currentItem().author;
    }
     
    private function currentTitle():String{
      return currentItem().title;
    }
    
    // TODO: Catch more advert types
    private function isAdvert():Boolean{
      return currentAuthor() == "OVA"
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // EVENT TRACKING BEHAVIOUR
    /////////////////////////////////////////////////////////////////////////////////////////
    
    private function trackEvent(category:String, action:String, label:String, value:Number):void{
      if(isAdvert()){
        category = CategoryType.PREROLL;
      }
      VideoEvent.track(_tracker, category, action, label, value);
    }    
    

    
    /////////////////////////////////////////////////////////////////////////////////////////
    // TIMER BEHAVIOUR
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // Timer initialization. Performed either immediately on plugin load 
    private function initTimer():void{
      _viewTimer = new Timer(nextViewTimerInterval(), 1);
      _viewTimer.addEventListener(TimerEvent.TIMER, timerListener);
      _viewTimer.addEventListener(TimerEvent.TIMER_COMPLETE, timerCompleteListener);
    }
    
    // Event handler for timer loop event
    private function timerListener(e:TimerEvent):void{}  
    
    // Event handler for timer complete event
    private function timerCompleteListener(e:TimerEvent):void{
      trackEvent(_category, "Heartbeat", _label, _channelViewTimerIntervals[_currentViewTimerIntervalIndex])
      initTimer();
      _viewTimer.start();
    }
    
    // FIXME: Remove old code
    private function resetPlayTimer():void{
      _viewTimer.start();
      _lastPlayTime = getTimer();
    }
    
    // FIXME: Use new timers
    private function secondsPlayed():Number{
      _timeWatched = (getTimer() - _lastPlayTime) / 1000;
      return _timeWatched;
    }
    
    // Get the next interval to run the timer for
    private function nextViewTimerInterval():int{
      if(_currentViewTimerIntervalIndex < _channelViewTimerIntervals.length){
        _currentViewTimerIntervalIndex += 1;
      }
      return (_channelViewTimerIntervals[_currentViewTimerIntervalIndex] * 1000)
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // EVENT HANDLERS
    /////////////////////////////////////////////////////////////////////////////////////////
    
    //////////////////////
    // PLAYER EVENTS
    /////////////////////
    
    private function playerReady(evt:PlayerEvent):void{
      log('Player is ready.');
    }
    
    // Fired whenever the player changes state (e.g. buffering, stopped etc)
    private function playerStateHandler(evt:PlayerStateEvent):void{
      switch(evt.newstate){
        case "PLAYING":
          // Only want to do this if the start event was triggered automatically
          // Otherwise we use the viewplay() event callback
          if(evt.oldstate != "PAUSED"){
            trackEvent(_category, VideoEvent.START, _label, 0);
            resetPlayTimer();
          }
          break;
          
        case "BUFFERING":
          break;
          
        case "IDLE":
          break;
                    
        case "PAUSED":
          if(evt.oldstate == "PLAYING"){
            trackEvent(_category, VideoEvent.PAUSE, _label, secondsPlayed());
          }
          break;
      }
    }
    
    
    
    //////////////////////
    // MEDIA EVENTS
    /////////////////////

    // Fired whenever the playback position or time changes
    private function mediaTime(evt:MediaEvent):void{
      _currentPosition = evt.position;
    }
    
    // Fired when the media is seeked forward or backwards
    private function mediaSeek(evt:MediaEvent):void{
      if(evt.offset > _currentPosition){
        trackEvent(_category, VideoEvent.SKIP_FORWARD, _label, 0);
      }else if(evt.offset < _currentPosition){
        trackEvent(_category, VideoEvent.SKIP_BACKWARD, _label, 0);
      }
    }
    
    // Fired when the media reaches the end 
    private function mediaComplete(evt:MediaEvent):void{
      trackEvent(_category, VideoEvent.END, _label, secondsPlayed());
    }
    
    // Fired when the volume goes up or down
    private function mediaVolume(evt:MediaEvent):void{
      if(evt.volume > _volume){
        trackEvent(_category, VideoEvent.INCREASE_VOLUME, _label, 0)
      }else if(evt.volume < _volume){
        trackEvent(_category, VideoEvent.DECREASE_VOLUME, _label, 0)
      }
      _volume = evt.volume;
    }
    
    // Fired when the media is muted
    private function mediaMute(evt:MediaEvent):void{
      if(evt.mute.toString() == "true"){
        trackEvent(_category, VideoEvent.MUTE, _label, 0);
      }
    }
    
    // Fired if there is an error when attempting playback
    private function mediaError(evt:MediaEvent):void{
      trackEvent(_category, VideoEvent.ERROR, evt.message, 0);
    } 
    

    
    //////////////////////
    // VIEW EVENTS
    /////////////////////
    
    private function viewFullscreen(evt:ViewEvent):void{
      if(evt.data.toString() == "true"){
        // Seem to get two events fired so we can track the state of the fullscreen independently
        if(_fullscreen == false){
          trackEvent(_category, VideoEvent.FULLSCREEN, _label, 0);  
        }
        _fullscreen = true;
      }else{
        if(_fullscreen == true){
          trackEvent(_category, VideoEvent.REDUCE_SCREEN, _label, 0);
        }
        _fullscreen = false;
      }
    }
    
    private function viewPlay(evt:ViewEvent):void{
      trackEvent(_category, VideoEvent.PLAY, _label, 0);
      resetPlayTimer();
    }
    
    //////////////////////////
    // UN-IMPLEMENTED EVENTS
    //////////////////////////
    // Media Events
    // private function mediaMeta(evt:MediaEvent):void{}
    // private function mediaLoaded(evt:MediaEvent):void{}
    // private function mediaBuffer(evt:MediaEvent):void{}
    // private function mediaBufferFull(evt:MediaEvent):void{}
    
    // Playlist Events
    // private function playlistLoaded(evt:PlaylistEvent):void{}
    // private function playlistUpdated(evt:PlaylistEvent):void{}
    // private function playlistItem(evt:PlaylistEvent):void{}
    
    // View Events
    // private function viewItem(evt:ViewEvent):void{}
    // private function viewLoad(evt:ViewEvent):void{}
    // private function viewNext(evt:ViewEvent):void{}
    // private function viewPause(evt:ViewEvent):void{}
    // private function viewPrev(evt:ViewEvent):void{}
    // private function viewRedraw(evt:ViewEvent):void{}
    // private function viewSeek(evt:ViewEvent):void{} 
    // private function viewStop(evt:ViewEvent):void{} 
    // private function viewVolume(evt:ViewEvent):void{} 
    
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // JAVASCRIPT EVENT HANDLER
    /////////////////////////////////////////////////////////////////////////////////////////    
    
    // Receive function calls from Javascript
    private function callFromJavaScript(action:String):void{
      switch(action){
        case "build":
          GATracker(_tracker).build();
          break;
      }
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // GENERIC HELPERS
    /////////////////////////////////////////////////////////////////////////////////////////

    // Logger for debugging purposes
    private function log(text:String):void{
      if(debug()){ 
        Logger.log(text.toString(), GoogleAnalytics.LOGGER_TYPE);
      }
    }

    // Debug mode?
    private function debug():Boolean{
      return _gaDebug;
    }
    
  }
}
