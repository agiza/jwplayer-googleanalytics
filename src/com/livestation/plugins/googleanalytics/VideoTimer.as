package com.livestation.plugins.googleanalytics {

  // * Watch Live Plugin; Just adds a button which links back to the live channel
  // public class VideoEvent extends Event {
  public class VideoTimer {


    public function start(){
      
    }
    
    public function stop(){
      
    }
    
    public function reset(){
      
    }
      
    public static function track(tracker:AnalyticsTracker, category:String, action:String, label:String, value:Number, noninteraction:Boolean=false):void{      
      tracker.trackEvent(category, action, label, value);
    }
    
  }
  
}