package com.livestation.plugins.googleanalytics {

  import com.google.analytics.AnalyticsTracker;
  import com.google.analytics.GATracker;
  
  //import flash.events.Event;

  // * Watch Live Plugin; Just adds a button which links back to the live channel
  // public class VideoEvent extends Event {
  public class VideoEvent {
    
    public static var START:String = "Start";
    public static var PLAY:String = "Play";
    public static var PAUSE:String = "Pause";
    public static var END:String = "End";
    public static var SKIP_FORWARD:String = "Skip forward";
    public static var SKIP_BACKWARD:String = "Skip backwards"; 
    public static var MUTE:String = "Mute";
    public static var INCREASE_VOLUME:String = "Increase volume";
    public static var DECREASE_VOLUME:String = "Decrease volume";
    public static var FULLSCREEN:String = "Switch to full screen";
    public static var REDUCE_SCREEN:String = "Switch to window screen";
    public static var ERROR:String = "Error";
      
      
    public static function track(tracker:AnalyticsTracker, category:String, action:String, label:String, value:Number, noninteraction:Boolean=false):void{      
      tracker.trackEvent(category, action, label, value, noninteraction);
    }
    
  }
  
}