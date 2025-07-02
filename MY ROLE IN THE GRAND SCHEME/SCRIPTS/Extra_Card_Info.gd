class_name ExtraCardData extends RefCounted

## Abstract base class for defining additional data to be saved with cards of a
## given type. The class contains information specific to that card type, and
## which is not needed by the Card itself (e.g. for display and interaction).
## Each subclass defines methods used to save and load the data.
