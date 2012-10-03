package com.livestation.plugins.googleanalytics {

  import com.google.analytics.AnalyticsTracker;
  import com.google.analytics.GATracker;
  
  //import flash.events.Event;

  // * Watch Live Plugin; Just adds a button which links back to the live channel
  // public class VideoEvent extends Event {
  public class CustomVariable {

    public static function set(tracker:AnalyticsTracker, id:int, name:String, value:String, scope:int=3):void{      
      tracker.setVar(id, name, value, scope);
    }
    
  }
  
}