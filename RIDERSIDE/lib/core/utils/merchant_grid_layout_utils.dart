/// Card ratios are width / height. The merchant grid needs taller cards on
/// phones because its inventory and action controls occupy more vertical space.
double merchantMenuCardAspectRatio(double screenWidth) =>
    screenWidth >= 600 ? 0.72 : 0.50;

/// The Book grid has a shorter card body and can use a denser layout.
double merchantBookCardAspectRatio(double contentWidth) =>
    contentWidth >= 600 ? 0.72 : 0.58;
