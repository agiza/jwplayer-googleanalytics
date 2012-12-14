package com.livestation.plugins.googleanalytics {

  import com.google.analytics.AnalyticsTracker;
  import com.google.analytics.GATracker;
  
  //import flash.events.Event;

  // * Watch Live Plugin; Just adds a button which links back to the live channel
  // public class VideoEvent extends Event {
  public class CustomVariable {
    
    private var _id:int;
    private var _name:String;
    private var _value:String;
    private var _scope:int;

    public static function set(tracker:AnalyticsTracker, id:int, name:String, value:String, scope:int=3):void{      
      tracker.setVar(id, name, value, scope);
    }
    
    public static function delete(tracker:AnalyticsTracker, id:int):void{      
      tracker.deleteVar(id);
    }
    
    // Getter and setter methods
    public function get id():int{
      return _id;
    }
    
    public function set id(value:int):void{
      _id = value;
    }
    
    public function get name():String{
      return _name;
    }
    
    public function set name(value:String):void{
      _name = value;
    }
    
    public function get value():String{
      return _value;
    }
    
    public function set value(value:String):void{
      _value = value;
    }    
    
    public function get scope():int{
      return _scope;
    }
    
    public function set scope(value:int):void{
      _scope = value;
    }    
    
  }
  
}