package com.livestation.plugins.googleanalytics {

  import com.longtailvideo.jwplayer.player.*;
  import com.longtailvideo.jwplayer.events.*;
  import com.longtailvideo.jwplayer.model.*;
  import com.longtailvideo.jwplayer.plugins.IPlugin;
  import com.longtailvideo.jwplayer.plugins.PluginConfig;
  import com.longtailvideo.jwplayer.utils.Configger;

  import com.google.analytics.AnalyticsTracker;
  import com.google.analytics.GATracker;
  import com.google.analytics.core.DomainNameMode;
  import com.google.analytics.core.Domain;
  
  import flash.events.*;
  import flash.display.MovieClip;
  import flash.external.ExternalInterface;
  import flash.utils.*;
  
  // * Watch Live Plugin; Just adds a button which links back to the live channel
  public class GoogleAnalytics extends MovieClip implements IPlugin {

    private var _player:IPlayer;
    private var _config:PluginConfig;
    private var _tracker:AnalyticsTracker;
    private var _gaUA:String;
    private var _gaMode:String = "Bridge";
    private var _gaDebug:Boolean = false;
    private var _trackAdverts:Boolean = false;
    private var _categoryPrefix:String = "";
    
    private var _label:String;
    private var _action:String;
    
    private var _timeWatched:int = 0;
    private var _lastPlayTime:int = 0;            
    
    public function GoogleAnalytics():void {}
     
    /** The initialize call is invoked by the player. **/
    public function initPlugin(player:IPlayer, cfg:PluginConfig):void {
      _player = player;
      _config = cfg;      
      _gaUA = config['accountid'];
      _gaDebug = config['debug'] || false;
      _label = config['label'];
      _action = config['action'];
      _trackAdverts = config['trackadverts'] || false;
      
      if(config["mode"] !== undefined){
        _gaMode = config["mode"];
      }
      
      ExternalInterface.addCallback("sendToActionscript", callFromJavaScript);
      
      if(_gaUA != null){
        //GATracker.autobuild = false;
        _tracker = new GATracker(this, _gaUA, _gaMode, _gaDebug);
        //_tracker.setAllowLinker(true);
        //_tracker.setAllowHash(true);
        _tracker.setDomainName(".livestation.com");
        // Initialize event listeners
        initializeEvents();
      }else{
        log("Please supply account ID as googleanalytics.accountid in configuration");
      }
    }

    // Required resize method
    public function resize(width:Number, height:Number):void {
     //nothing
    }
    
    // Config object
    public function get config():PluginConfig {
      return _player.config.pluginConfig('googleanalytics');
    }
    
    // ID of the plugin
    public function get id():String {
      return "googleanalytics";
    }
    
    // Receive function calls from Javascript
    private function callFromJavaScript(action:String):void{
      switch(action){
        case "build":
          GATracker(_tracker).build();
          break;
      }
    }

    // Logger for debugging purposes
    private function log(text:String):void{
      if(_gaDebug){
        ExternalInterface.call('console.log', text);
      }
    }    
    
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
    
    private function trackEvent(category:String, action:String, label:String, value:Number):void{
      if(_trackAdverts){
        log("Tracking adverts");
        if(currentAuthor() == "OVA"){
          log("Tracking Advertising Event");
          _tracker.trackEvent(_categoryPrefix + "Advertising: " + category, action, label, value);
        }else{
          log("Tracking stream event");
          _tracker.trackEvent(_categoryPrefix + category, action, label, value);
        }
      }else{
        log("Not tracking adverts");
        if(currentAuthor() != "OVA"){
          log('Tracking event fired');
          _tracker.trackEvent(_categoryPrefix + category, action, label, value);
        }
      }
    }
    
    private function initializeEvents():void{
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
    
    
    
    // Player Ready
    private function playerReady(evt:PlayerEvent):void{
      log('Player is ready!');
    }
    
    // Media Events
    private function mediaLoaded(evt:MediaEvent):void{}
    private function mediaBuffer(evt:MediaEvent):void{}
    private function mediaBufferFull(evt:MediaEvent):void{}
    private function mediaTime(evt:MediaEvent):void{}
    
    private function mediaComplete(evt:MediaEvent):void{
      trackEvent('Video Completed', _action, _label, 0)
    }
    
    private function mediaVolume(evt:MediaEvent):void{}
    private function mediaMute(evt:MediaEvent):void{}
    private function mediaError(evt:MediaEvent):void{
      trackEvent('Error Info', _action, evt.message, 0);
    }
    private function mediaMeta(evt:MediaEvent):void{}
    
    // Player State Event
    private function playerStateHandler(evt:PlayerStateEvent):void{
      switch(evt.newstate){
        case "PLAYING":
          log("Playing...");
          trackEvent('Video Plays', _action, _label, 0);
          resetPlayTimer();
          break;
          
        case "BUFFERING":
          log("Buffering...");
          //_tracker.trackEvent('Video Buffers', _action, _label);
          break;
          
        case "IDLE":
          log("Idle...");
          if(evt.oldstate == "PLAYING"){
            log('Tracking seconds played...' + secondsPlayed().toString());
            trackEvent('Seconds Played', _action, _label, secondsPlayed())
          }
          break;
          
        case "PAUSED":
          log("Paused");
          if(evt.oldstate == "PLAYING"){
            log('Tracking seconds played...' + secondsPlayed().toString());
            trackEvent('Seconds Played', _action, _label, secondsPlayed())
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
      log('Fullscreen mode toggled');
      if(evt.data.toString() == "true"){
        log("Fullscreen mode active");
        trackEvent('Fullscreen Mode', _action, _label, 0);
      }
    }
    private function viewItem(evt:ViewEvent):void{}
    private function viewLoad(evt:ViewEvent):void{}
    private function viewNext(evt:ViewEvent):void{}
    private function viewPause(evt:ViewEvent):void{}
    private function viewPlay(evt:ViewEvent):void{
      //Perform this during the playStateHandler otherwise we will get duplicate play events.
    }
    private function viewPrev(evt:ViewEvent):void{}
    private function viewRedraw(evt:ViewEvent):void{}
    private function viewSeek(evt:ViewEvent):void{} 
    private function viewStop(evt:ViewEvent):void{} 
    private function viewVolume(evt:ViewEvent):void{} 
  }
}
