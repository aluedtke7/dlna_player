import 'package:event_bus/event_bus.dart';

class VolumeChangedEvent {
  double volume;

  VolumeChangedEvent(this.volume);
}

EventBus eventBus = EventBus();
