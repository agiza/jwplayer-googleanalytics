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
    
    private var ANALYTICS_INIT_ERROR:String = "Please supply account ID as googleanalytics.accountid in configuration";
    
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
      
      log("Started Google Analytics Plugin v2.0")
      initConfig();      
      initJavaScriptCallbacks();
      initGoogleAnalyticsTracker();
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
      // Player Ready
      _player.addEventListener(PlayerEvent.JWPLAYER_READY, playerReady);
      
      // Media Events
      _player.addEventListener(MediaEvent.JWPLAYER_MEDIA_LOADED, mediaLoaded);
      _player.addEventListener(MediaEvent.JWPLAYER_MEDIA_BUFFER, mediaBuffer);
      _player.addEventListener(MediaEvent.JWPLAYER_MEDIA_BUFFER_FULL, mediaBufferFull);
      _player.addEventListener(MediaEvent.JWPLAYER_MEDIA_TIME, mediaTime);
      _player.addEventListener(MediaEvent.JWPLAYER_MEDIA_COMPLETE, mediaComplete);
      _player.addEventListener(MediaEvent.JWPLAYER_MEDIA_VOLUME, mediaVolume);
      _player.addEventListener(MediaEvent.JWPLAYER_MEDIA_MUTE, mediaMute);
      _player.addEventListener(MediaEvent.JWPLAYER_MEDIA_ERROR, mediaError);
      _player.addEventListener(MediaEvent.JWPLAYER_MEDIA_META, mediaMeta);
      _player.addEventListener(MediaEvent.JWPLAYER_MEDIA_SEEK, mediaSeek);
      
      // Player State Events
      _player.addEventListener(PlayerStateEvent.JWPLAYER_PLAYER_STATE, playerStateHandler);
      
      // Playlist Events
      _player.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_LOADED, playlistLoaded);
      _player.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_UPDATED, playlistUpdated);
      _player.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_ITEM, playlistItem);
      
      // View Events
      _player.addEventListener(ViewEvent.JWPLAYER_VIEW_FULLSCREEN, viewFullscreen);
      _player.addEventListener(ViewEvent.JWPLAYER_VIEW_ITEM, viewItem);
      _player.addEventListener(ViewEvent.JWPLAYER_VIEW_LOAD, viewLoad);
      _player.addEventListener(ViewEvent.JWPLAYER_VIEW_NEXT, viewNext);
      _player.addEventListener(ViewEvent.JWPLAYER_VIEW_PAUSE, viewPause);
      _player.addEventListener(ViewEvent.JWPLAYER_VIEW_PLAY, viewPlay);
      _player.addEventListener(ViewEvent.JWPLAYER_VIEW_PREV, viewPrev);
      _player.addEventListener(ViewEvent.JWPLAYER_VIEW_REDRAW, viewRedraw);
      _player.addEventListener(ViewEvent.JWPLAYER_VIEW_SEEK, viewSeek);
      _player.addEventListener(ViewEvent.JWPLAYER_VIEW_STOP, viewStop);
      _player.addEventListener(ViewEvent.JWPLAYER_VIEW_VOLUME, viewVolume);      
      
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
    
    private function secondsPlayed():Number{
      _timeWatched = (getTimer() - _lastPlayTime) / 1000;
      return _timeWatched;
    }
    
    private function currentItem():PlaylistItem{
     return _player.playlist.currentItem;
    }
    
    private function currentAuthor():String{
      return currentItem().author;
    }
     
    private function currentTitle():String{
      return currentItem().title;
    }
    
    private function resetPlayTimer():void{
      _lastPlayTime = getTimer();
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
    // EVENT HANDLERS
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // Player Ready
    private function playerReady(evt:PlayerEvent):void{
      log('Player is ready.');
    }
    
    // Media Events
    private function mediaLoaded(evt:MediaEvent):void{}
    private function mediaBuffer(evt:MediaEvent):void{}
    private function mediaBufferFull(evt:MediaEvent):void{}
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
    private function mediaMeta(evt:MediaEvent):void{}
    
    // Player State Event
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
    
    // Playlist Events
    private function playlistLoaded(evt:PlaylistEvent):void{}
    private function playlistUpdated(evt:PlaylistEvent):void{}
    private function playlistItem(evt:PlaylistEvent):void{}
    
    // View Events
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
    private function viewItem(evt:ViewEvent):void{}
    private function viewLoad(evt:ViewEvent):void{}
    private function viewNext(evt:ViewEvent):void{}
    private function viewPause(evt:ViewEvent):void{}
    private function viewPlay(evt:ViewEvent):void{
      trackEvent(_category, VideoEvent.PLAY, _label, 0);
      resetPlayTimer();
    }
    private function viewPrev(evt:ViewEvent):void{}
    private function viewRedraw(evt:ViewEvent):void{}
    private function viewSeek(evt:ViewEvent):void{} 
    private function viewStop(evt:ViewEvent):void{} 
    private function viewVolume(evt:ViewEvent):void{} 
    
    
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
        Logger.log(text.toString(), "LS-GOOGLEANALYTICS");
      }
    }

    // Debug mode?
    private function debug():Boolean{
      return _gaDebug;
    }
    
  }
}
