import 'package:leaflet_map/src/utility/helper.dart' as h;

typedef void EventFunc([dynamic context, AppEvent appEvent]);

void falseFn([dynamic context, AppEvent evt]){
  return;
}

abstract class Evented {
  String _id;
  String get id => this._id;
  bool _firing;

  Map<String, List<Listener>> _events;
  List<Evented> _eventParents;

  Evented():
    this._id = h.getNextId();

  on(dynamic types, [EventFunc fn, dynamic context]){
    if (types is String){
      List<String> events = types.split(' ');
      for(String name in events){
        this._on(name, fn, context, false);
      }
    } else if (types is Map<String, EventFunc>){
      for(String key in types.keys){
        this._on(key, types[key], context, false);
      }
    }
  }

  addEventListener(dynamic types, [EventFunc fn, dynamic context]){
    this.on(types, fn, context);
  }

  _on(String name, EventFunc fn, dynamic context, bool once){
    List<Listener> listeners = this._getListeners(name);
    dynamic ctx = context == this ? null : context;

    for(Listener ls in listeners){
      if (ls.fn == fn && ls.context == ctx){
        return;
      }
    }
    listeners.add(new Listener(fn, ctx, once));
  }

  removeEventListener({dynamic types, EventFunc fn, dynamic context}){
    this.off(types: types, fn: fn, context: context);
  }

  off({dynamic types, EventFunc fn, dynamic context}){
    dynamic ctx = context == this ? null: context;

    if(types == null){
      this._events = null;
    } else if(types is String){
      for(String name in types.split(' ')){
        this._off(name, fn, ctx);
      }
    } else if (types is Map<String, EventFunc>){
      for(String key in types.keys){
        this._off(key, types[key], ctx);
      }
    }
  }

  _off(String name, EventFunc fn, dynamic context){
    List<Listener> listeners = this._getListeners(name);
    if(listeners.isEmpty){
      return;
    }
    if(fn == null){
      for(Listener l in listeners){
        l.fn = falseFn;
      }
      this._events.remove(name);
      return;
    }

    Listener l = this._findListener(listeners, fn, context);
    if(l != null){
      l.fn = falseFn;
      if(this._firing){
        listeners = new List<Listener>.from(listeners).toList();
        this._events[name] = listeners;
      }
      listeners.remove(l);
    }
  }



  _findListener(List<Listener> listeners, EventFunc fn, dynamic context){
    Listener found;
    for(Listener l in listeners){
      if (l.context == context && l.fn == fn){
        found = l;
        break;
      }
    }
    return found;
  }

  _getListeners(String name){
    List<Listener> listeners;

    if(this._events == null){
      this._events = <String, List<Listener>>{};
    }


    if(!this._events.containsKey(name)){
      listeners = <Listener>[];
      this._events[name] = listeners;
    } else {
      listeners = this._events[name];
    }
    return listeners;
  }

  fireEvent(String name, [EventData data,bool propagate]){
    this.fire(name, data, propagate);
  }
  
  runEventFunc(String eventType, EventFunc func, dynamic context){
    if(func is Function){
      context = h.setOrDefault(context, this);
      EventData data = new EventData(context);
      AppEvent appEvent = new AppEvent(type: eventType, target: this, eventData: data);
      func(context, appEvent);
    }
  }

  fire(String name, [EventData data,bool propagate=false]){
    if(!this.listens(name, propagate)){
      return;
    }
    data = h.setOrDefault(data, new EventData(this));

    AppEvent appEvent = new AppEvent(type:name, eventData:data, target:this);
    this._firing = true;
    List<Listener> listeners = this._getListeners(name);
    List<Listener> delL = <Listener>[];

    for(Listener l in listeners){
      l.fn(l.context, appEvent);
      if(l.once){
        delL.add(l);
      }
    }

    for(Listener l in delL){
      listeners.remove(l);
    }

    this._firing = false;

    if(propagate){
      this._propagateEvent(appEvent);
    }
  }

  _propagateEvent(AppEvent event){
    if(this._eventParents == null){
      return;
    }
    for(Evented e in this._eventParents){
      e.fire(event.type, event.eventData, true);
    }
  }

  hasEventListeners(String name, bool propagate){
    this.listens(name, propagate);
  }

  bool listens(String name, bool propagate){
    List<Listener> listeners = this._getListeners(name);
    if(listeners.isNotEmpty) {
      return true;
    }

    if(propagate && this._eventParents != null){
      for(Evented e in this._eventParents){
        if (e.listens(name, propagate)){
          return true;
        }
      }
    }

    return false;
  }

  once(dynamic types, EventFunc fn, dynamic context){
    if(types is Map<String, EventFunc>){
      for(String name in types.keys){
        this.once(name, types[name], context);
      }
      return;
    }

    this._on(types, fn, context, true);
  }

  addOneTimeEventListener(dynamic types, EventFunc fn, dynamic context) {
    this.once(types, fn, context);
  }

  addParent(Evented obj){
    List<Evented> parents = this._getParents();
    for(int i=0; i < parents.length; i++){
      if (parents[i].id == obj.id){
        parents[i] = obj;
        return;
      }
    }
    parents.add(obj);
  }

  removeParent(Evented obj){
    List<Evented> parents = this._getParents();
    parents.removeWhere((e)=> e.id == obj.id);
  }

  List<Evented> _getParents() {
    if(this._eventParents == null){
      this._eventParents = <Evented>[];
    }
    return this._eventParents;
  }
}

class Listener {
  bool once;
  EventFunc fn;
  dynamic context;
  Listener(this.fn, this.context, [this.once]);
}

class EventData {
  dynamic data;
  dynamic context;
  bool pinch;
  EventData(this.context, [this.data, this.pinch]);
}

class AppEvent {
  String type;
  dynamic target;
  EventData eventData;

  AppEvent({this.type, this.eventData, this.target});
}