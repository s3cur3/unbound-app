/******************************************************************************\
* Copyright (C) 2012-2013 Leap Motion, Inc. All rights reserved.               *
* Leap Motion proprietary and confidential. Not for distribution.              *
* Use subject to the terms of the Leap Motion SDK Agreement available at       *
* https://developer.leapmotion.com/sdk_agreement, or another agreement         *
* between Leap Motion and you, your company or other organization.             *
\******************************************************************************/

#import <Foundation/Foundation.h>

/* ************************************************************************
Do not be alarmed by the copyright notice above. Please bear with us as we
work with our lawyers to finalize a permissive license for this code.

This wrapper works by doing a deep copy of the bulk of the hand and finger
hierarchy as soon as you the user requests `[controller frame]`. This is
enables us to set up the appropriate linkage between LeapHand and
LeapPointable ObjectiveC objects.

The motions API forced our hand to move the Frame and Hand objects towards
thin wrappers. Each now contains a pointer to its corresponding C++ object.
The screen calibration API brought Pointable objects to wrap and keep
around a C++ Leap::Pointable object as well.

Because the wrapped C++ object is kept around, attributes such as position
and velocity now have their ObjectiveC objects created lazily.

Major Leap API features supported in this wrapper today:
* Obtaining data through both polling (LeapController only) as well as
  through callbacks
* Support for single-threaded callbacks through NSNotification objects
  (LeapListener), in addition to ObjectiveC delegates (LeapDelegate)
* Querying for fingers, tools, or general pointables
* Various hand/finger properties: palmNormal, direction, sphereRadius,
  and more
* Vector math helper functions: pitch, roll, raw, vector add, scalar
  multiply, dot product, cross product, LeapMatrix, and more
* Querying back up the hierarchy, e.g. `[finger hand]` or `[hand frame]`
* Indexing fingers or tools by persistent ID e.g. `[frame finger:ID]`
  or `[hand tool:ID]`
* LeapConfig API (for forthcoming features)
* Motions API
* Screen positioning API

Notes:
* Class names are prefixed by Leap, although LM and LPM were considered.
  Users may change the prefix locally, for example:
    sed -i '.bak' 's/Leap\([A-NP-Z]\)/LPM\1/g' LeapObjectiveC.*
    # above regexp matches LeapController, LeapVector, not LeapObjectiveC
* Requires XCode 4.2+, relies on Automatic Reference Counting (ARC),
  minimum target OS X 10.7
* Contributions are welcome

*************************************************************************/

//////////////////////////////////////////////////////////////////////////
//VECTOR
/**
 * The LeapVector class represents a three-component mathematical vector or point
 * such as a direction or position in three-dimensional space.
 *
 * The Leap software employs a right-handed Cartesian coordinate system.
 * Values given are in units of real-world millimeters. The origin is centered
 * at the center of the Leap device. The x- and z-axes lie in the horizontal
 * plane, with the x-axis running parallel to the long edge of the device.
 * The y-axis is vertical, with positive values increasing upwards (in contrast
 * to the downward orientation of most computer graphics coordinate systems).
 * The z-axis has positive values increasing away from the computer screen.
 *
 * <img src="../docs/images/Leap_Axes.png"/>
 */
@interface LeapVector : NSObject

/** 
 * Creates a new LeapVector with the specified component values. 
 * @param x The horizontal component.
 * @param y The vertical component.
 * @param z The depth component.
 */
- (id)initWithX:(float)x y:(float)y z:(float)z;
/** 
 * Copies the specified LeapVector. 
 * @param vector The LeapVector to copy.
 */
- (id)initWithVector:(const LeapVector *)vector;
- (NSString *)description;
/**
 * The magnitude, or length, of this vector.
 *
 * The magnitude is the L2 norm, or Euclidean distance between the origin and
 * the point represented by the (x, y, z) components of this LeapVector object.
 *
 * @returns The length of this vector.
 */
- (float)magnitude;
@property (nonatomic, getter = magnitude, readonly)float magnitude;
/**
 * The square of the magnitude, or length, of this vector.
 *
 * @returns The square of the length of this vector.
 */
- (float)magnitudeSquared;
@property (nonatomic, getter = magnitudeSquared, readonly)float magnitudeSquared;
/**
 * The distance between the point represented by this LeapVector
 * object and a point represented by the specified LeapVector object.
 *
 * @param vector A LeapVector object.
 * @returns The distance from this point to the specified point.
 */
- (float)distanceTo:(const LeapVector *)vector;
/**
 *  The angle between this vector and the specified vector in radians.
 *
 * The angle is measured in the plane formed by the two vectors. The
 * angle returned is always the smaller of the two conjugate angles.
 * Thus `[A angleTo:B] == [B angleTo:A]` and is always a positive
 * value less than or equal to pi radians (180 degrees).
 *
 * If either vector has zero length, then this function returns zero.
 *
 * <img src="../docs/images/Math_AngleTo.png"/>
 *
 * @param vector A LeapVector object.
 * @returns The angle between this vector and the specified vector in radians.
 */
- (float)angleTo:(const LeapVector *)vector;
/**
 *  The pitch angle in radians.
 *
 * Pitch is the angle between the negative z-axis and the projection of
 * the vector onto the y-z plane. In other words, pitch represents rotation
 * around the x-axis.
 * If the vector points upward, the returned angle is between 0 and pi radians
 * (180 degrees); if it points downward, the angle is between 0 and -pi radians.
 *
 * <img src="../docs/images/Math_Pitch_Angle.png"/>
 *
 * @returns The angle of this vector above or below the horizon (x-z plane).
 */
- (float)pitch;
@property (nonatomic, getter = pitch, readonly)float pitch;
/**
 *  The roll angle in radians.
 *
 * Roll is the angle between the y-axis and the projection of
 * the vector onto the x-y plane. In other words, roll represents rotation
 * around the z-axis. If the vector points to the left of the y-axis,
 * then the returned angle is between 0 and pi radians (180 degrees);
 * if it points to the right, the angle is between 0 and -pi radians.
 *
 * <img src="../docs/images/Math_Roll_Angle.png"/>
 *
 * Use this function to get roll angle of the plane to which this vector is a
 * normal. For example, if this vector represents the normal to the palm,
 * then this function returns the tilt or roll of the palm plane compared
 * to the horizontal (x-z) plane.
 *
 * @returns The angle of this vector to the right or left of the y-axis.
 */
- (float)roll;
@property (nonatomic, getter = roll, readonly)float roll;
/**
 *  The yaw angle in radians.
 *
 * Yaw is the angle between the negative z-axis and the projection of
 * the vector onto the x-z plane. In other words, yaw represents rotation
 * around the y-axis. If the vector points to the right of the negative z-axis,
 * then the returned angle is between 0 and pi radians (180 degrees);
 * if it points to the left, the angle is between 0 and -pi radians.
 *
 * <img src="../docs/images/Math_Yaw_Angle.png"/>
 *
 * @returns The angle of this vector to the right or left of the negative z-axis.
 */
- (float)yaw;
@property (nonatomic, getter = yaw, readonly)float yaw;
/** Adds two vectors. 
 * @param vector The LeapVector addend.
 */
- (LeapVector *)plus:(const LeapVector *)vector;
/** Subtract a vector from this vector 
 * @param vector the LeapVector subtrahend.
 */
- (LeapVector *)minus:(const LeapVector *)vector;
/** Negate this vector. */
- (LeapVector *)negate;
/** Multiply this vector by a number. 
 * @param scalar The scalar factor.
 */
- (LeapVector *)times:(float)scalar;
/** Divide this vector by a number. 
 * @param scalar The scalar divisor;
 */
- (LeapVector *)divide:(float)scalar;
// not provided: unary assignment operators (plus_equals, minus_equals)
// user should emulate with above operators
/** 
 * Checks LeapVector equality.
 * Vectors are equal if each corresponding component is equal.
 * @param vector The LeapVector to compare.
 */
- (BOOL)equals:(const LeapVector *)vector;
// not provided: not_equals
// user should emulate with !v.equals(...)
/**
 *  The dot product of this vector with another vector.
 *
 * The dot product is the magnitude of the projection of this vector
 * onto the specified vector.
 *
 * <img src="../docs/images/Math_Dot.png"/>
 *
 * @param vector A LeapVector object.
 * @returns The dot product of this vector and the specified vector.
 */
- (float)dot:(const LeapVector *)vector;
/**
 *  The cross product of this vector and the specified vector.
 *
 * The cross product is a vector orthogonal to both original vectors.
 * It has a magnitude equal to the area of a parallelogram having the
 * two vectors as sides. The direction of the returned vector is
 * determined by the right-hand rule. Thus `[A cross:B] == 
 * [[B negate] cross:A]`.
 *
 * <img src="../docs/images/Math_Cross.png"/>
 *
 * @param vector A LeapVector object.
 * @returns The cross product of this vector and the specified vector.
 */
- (LeapVector *)cross:(const LeapVector *)vector;
/**
 *  A normalized copy of this vector.
 *
 * A normalized vector has the same direction as the original vector,
 * but with a length of one.
 *
 * @returns A LeapVector object with a length of one, pointing in the same
 * direction as this Vector object.
 */
- (LeapVector *)normalized;
@property (nonatomic, getter = normalized, readonly)LeapVector *normalized;
/** Returns an NSArray object containing the vector components in the 
 * order: x, y, z.
 */
- (NSArray *)toNSArray;
@property (nonatomic, getter = toNSArray, readonly)NSArray *toNSArray;
- (NSMutableData *)toFloatPointer;
@property (nonatomic, getter = toFloatPointer, readonly)NSMutableData *toFloatPointer;
// not provided: toVector4Type
// no templates, and ObjectiveC does not have a common math vector type
/** The zero vector: (0, 0, 0) */
+ (LeapVector *)zero;
/** The x-axis unit vector: (1, 0, 0) */
+ (LeapVector *)xAxis;
/** The y-axis unit vector: (0, 1, 0) */
+ (LeapVector *)yAxis;
/** The z-axis unit vector: (0, 0, 1) */
+ (LeapVector *)zAxis;
/** The unit vector pointing left along the negative x-axis: (-1, 0, 0) */
+ (LeapVector *)left;
/** The unit vector pointing right along the positive x-axis: (1, 0, 0) */
+ (LeapVector *)right;
/** The unit vector pointing down along the negative y-axis: (0, -1, 0) */
+ (LeapVector *)down;
/** The unit vector pointing up along the positive y-axis: (0, 1, 0) */
+ (LeapVector *)up;
/** The unit vector pointing forward along the negative z-axis: (0, 0, -1) */
+ (LeapVector *)forward;
/** The unit vector pointing backward along the positive z-axis: (0, 0, 1) */
+ (LeapVector *)backward;

/** The horizontal component. */
@property (nonatomic, assign, readonly)float x;
/** The vertical component. */
@property (nonatomic, assign, readonly)float y;
/** The depth component. */
@property (nonatomic, assign, readonly)float z;

@end

//////////////////////////////////////////////////////////////////////////
//MATRIX
/**
 *  The LeapMatrix class represents a transformation matrix.
 *
 * To use this class to transform a <LeapVector>, construct a matrix containing the
 * desired transformation and then use the <[LeapMatrix transformPoint:]> or
 * <[LeapMatrix transformDirection:]> functions to apply the transform.
 *
 * Transforms can be combined by multiplying two or more transform matrices using
 * the <[LeapMatrix times:]> function.
 */
@interface LeapMatrix : NSObject

/**
 *  Constructs a transformation matrix from the specified basis and translation vectors.
 *
 * @param xBasis A <LeapVector> specifying rotation and scale factors for the x-axis.
 * @param yBasis A <LeapVector> specifying rotation and scale factors for the y-axis.
 * @param zBasis A <LeapVector> specifying rotation and scale factors for the z-axis.
 * @param origin A <LeapVector> specifying translation factors on all three axes.
 */
- (id)initWithXBasis:(const LeapVector *)xBasis yBasis:(const LeapVector *)yBasis zBasis:(const LeapVector *)zBasis origin:(const LeapVector *)origin;
/** 
 * Constructs a copy of the specified Matrix object. 
 * @param matrix the LeapMatrix to copy.
 */
- (id)initWithMatrix:(LeapMatrix *)matrix;
/**
 *  Constructs a transformation matrix specifying a rotation around the specified vector.
 *
 * @param axis A <LeapVector> specifying the axis of rotation.
 * @param angleRadians The amount of rotation in radians.
 */
- (id)initWithAxis:(const LeapVector *)axis angleRadians:(float)angleRadians;
/**
 *  Constructs a transformation matrix specifying a rotation around the specified vector
 * and a translation by the specified vector.
 *
 * @param axis A <LeapVector> specifying the axis of rotation.
 * @param angleRadians The angle of rotation in radians.
 * @param translation A <LeapVector> representing the translation part of the transform.
 */
- (id)initWithAxis:(const LeapVector *)axis angleRadians:(float)angleRadians translation:(const LeapVector *)translation;
- (NSString *)description;
// not provided: setRotation
// This was mainly an internal helper function for the above constructors
/**
 *  Transforms a vector with this matrix by transforming its rotation,
 * scale, and translation.
 *
 * Translation is applied after rotation and scale.
 *
 * @param point A <LeapVector> representing the 3D position to transform.
 * @returns A new <LeapVector> representing the transformed original.
 */
- (LeapVector *)transformPoint:(const LeapVector *)point;
/**
 *  Transforms a vector with this matrix by transforming its rotation and
 * scale only.
 *
 * @param direction The <LeapVector> to transform.
 * @returns A new <LeapVector> representing the transformed original.
 */
- (LeapVector *)transformDirection:(const LeapVector *)direction;
/**
 *  Multiply transform matrices.
 *
 * Combines two transformations into a single equivalent transformation.
 *
 * @param other A LeapMatrix to multiply on the right hand side.
 * @returns A new LeapMatrix representing the transformation equivalent to
 * applying the other transformation followed by this transformation.
 */
- (LeapMatrix *)times:(const LeapMatrix *) other;
// not provided: unary assignment operator times_equals
/** 
 * Compare LeapMatrix equality component-wise. 
 *
 * @param other The LeapMatrix object to compare.
 * @return YES, if the corresponding elements in the two matrices are equal.
 */
- (BOOL)equals:(const LeapMatrix *) other;
// not provided: not_equals
/**
 *  Converts a LeapMatrix object to a 9-element NSArray object.
 *
 * The elements of the matrix are inserted into the array in row-major order.
 *
 * Translation factors are discarded.
 */
- (NSMutableArray *)toNSArray3x3;
@property (nonatomic, getter = toNSArray3x3, readonly)NSMutableArray *toNSArray3x3;
/**
 *  Converts a LeapMatrix object to a 16-element NSArray object.
 *
 * The elements of the matrix are inserted into the array in row-major order.
 */
- (NSMutableArray *)toNSArray4x4;
@property (nonatomic, getter = toNSArray4x4, readonly)NSMutableArray *toNSArray4x4;
/**
 *  Returns the identity matrix specifying no translation, rotation, and scale.
 *
 * @returns The identity matrix.
 */
+ (LeapMatrix *)identity;

/** The rotation and scale factors for the x-axis. */
@property (nonatomic, strong, readonly)LeapVector *xBasis;
/** The rotation and scale factors for the y-axis. */
@property (nonatomic, strong, readonly)LeapVector *yBasis;
/** The rotation and scale factors for the z-axis. */
@property (nonatomic, strong, readonly)LeapVector *zBasis;
/** The translation factors for all three axes. */
@property (nonatomic, strong, readonly)LeapVector *origin;

@end

//////////////////////////////////////////////////////////////////////////
//CONSTANTS
/** The constant pi as a single precision floating point number. */
extern const float LEAP_PI;
/**
 * The constant ratio to convert an angle measure from degrees to radians.
 * Multiply a value in degrees by this constant to convert to radians.
 */
extern const float LEAP_DEG_TO_RAD;
/**
 * The constant ratio to convert an angle measure from radians to degrees.
 * Multiply a value in radians by this constant to convert to degrees.
 */
extern const float LEAP_RAD_TO_DEG;

/**
 * The supported types of gestures.
 */
typedef enum LeapGestureType {
    LEAP_GESTURE_TYPE_INVALID = -1, /**< An invalid type. */
    LEAP_GESTURE_TYPE_SWIPE = 1, /**< A straight line movement by the hand with fingers extended. */
    LEAP_GESTURE_TYPE_CIRCLE = 4, /**< A circular movement by a finger. */
    LEAP_GESTURE_TYPE_SCREEN_TAP = 5, /**< A forward tapping movement by a finger. */
    LEAP_GESTURE_TYPE_KEY_TAP = 6, /**< A downward tapping movement by a finger. */
} LeapGestureType;

/**
 * The possible gesture states.
 */
typedef enum LeapGestureState {
    LEAP_GESTURE_STATE_INVALID = -1, /**< An invalid state */
    LEAP_GESTURE_STATE_START = 1, /**< The gesture is starting. Just enough has happened to recognize it. */
    LEAP_GESTURE_STATE_UPDATE = 2, /**< The gesture is in progress. (Note: not all gestures have updates). */
    LEAP_GESTURE_STATE_STOP = 3, /**< The gesture has completed or stopped. */
} LeapGestureState;

//////////////////////////////////////////////////////////////////////////
//POINTABLE
@class LeapFrame;
@class LeapHand;

/**
 * The LeapPointable class reports the physical characteristics of a detected finger or tool.
 *
 * Both fingers and tools are classified as LeapPointable objects. Use the 
 * <[LeapPointable isFinger]> function to determine whether a pointable object
 * represents a finger. Use the <[LeapPointable isTool]> function to determine 
 * whether a pointable object represents a tool. The Leap classifies a detected 
 * entity as a tool when it is thinner, straighter, and longer than a typical finger.
 *
 * Note that LeapPointable objects can be invalid, which means that they do not contain
 * valid tracking data and do not correspond to a physical entity. Invalid LeapPointable
 * objects can be the result of asking for a pointable object using an ID from an
 * earlier frame when no pointable objects with that ID exist in the current frame.
 * A pointable object created from the LeapPointable constructor is also invalid.
 * Test for validity with the <[LeapPointable isValid]> function.
 */
@interface LeapPointable : NSObject

- (NSString *)description;
/**
 * A unique ID assigned to this LeapPointable object, whose value remains the
 * same across consecutive frames while the tracked finger or tool remains
 * visible. If tracking is lost (for example, when a finger is occluded by
 * another finger or when it is withdrawn from the Leap field of view), the
 * Leap may assign a new ID when it detects the entity in a future frame.
 *
 * Use the ID value with the <[LeapFrame pointable:]> function to find this
 * LeapPointable object in future frames.
 *
 * @returns The ID assigned to this LeapPointable object.
 */
- (int32_t)id;
@property (nonatomic, getter = id, readonly)int32_t id;
/**
 * The tip position in millimeters from the Leap origin.
 *
 * @returns The <LeapVector> containing the coordinates of the tip position.
 */
- (LeapVector *)tipPosition;
@property (nonatomic, getter = tipPosition, readonly)LeapVector *tipPosition;
/**
 * The rate of change of the tip position in millimeters/second.
 *
 * @returns The <LeapVector> containing the coordinates of the tip velocity.
 */
- (LeapVector *)tipVelocity;
@property (nonatomic, getter = tipVelocity, readonly)LeapVector *tipVelocity;
/**
 * The direction in which this finger or tool is pointing.
 *
 * The direction is expressed as a unit vector pointing in the same
 * direction as the tip.
 *
 * <img src="../docs/images/Leap_Finger_Model.png"/>
 *
 * @returns The <LeapVector> pointing in the same direction as the tip of this
 * LeapPointable object.
 */
- (LeapVector *)direction;
@property (nonatomic, getter = direction, readonly)LeapVector *direction;
/**
 * The estimated width of the finger or tool in millimeters.
 *
 * The reported width is the average width of the visible portion of the
 * finger or tool from the hand to the tip. If the width isn't known,
 * then a value of 0 is returned.
 *
 * @returns The estimated width of this LeapPointable object.
 */
- (float)width;
@property (nonatomic, getter = width, readonly)float width;
/**
 * The estimated length of the finger or tool in millimeters.
 *
 * The reported length is the visible length of the finger or tool from the
 * hand to tip. If the length isn't known, then a value of 0 is returned.
 *
 * @returns The estimated length of this LeapPointable object.
 */
- (float)length;
@property (nonatomic, getter = length, readonly)float length;
/**
 * Whether or not the LeapPointable is believed to be a finger.
 * Fingers are generally shorter, thicker, and less straight than tools.
 *
 * @returns YES, if this LeapPointable is classified as a <LeapFinger>.
 */
- (BOOL)isFinger;
@property (nonatomic, getter = isFinger, readonly)BOOL isFinger;
/**
 * Whether or not the LeapPointable is believed to be a tool.
 * Tools are generally longer, thinner, and straighter than fingers.
 *
 * @returns YES, if this LeapPointable is classified as a <LeapTool>.
 */
- (BOOL)isTool;
@property (nonatomic, getter = isTool, readonly)BOOL isTool;
/**
 * Reports whether this is a valid LeapPointable object.
 *
 * @returns YES, if this LeapPointable object contains valid tracking data.
 */
- (BOOL)isValid;
@property (nonatomic, getter = isValid, readonly)BOOL isValid;
/**
 * The <LeapFrame> associated with this LeapPointable object.
 *
 * @returns The associated <LeapFrame> object, if available; otherwise,
 * an invalid LeapFrame object is returned.
 */
- (LeapFrame *)frame;
@property (nonatomic, weak, getter = frame, readonly)LeapFrame *frame;
/**
 * The <LeapHand> associated with this finger or tool.
 *
 * @returns The associated <LeapHand> object, if available; otherwise,
 * an invalid LeapHand object is returned.
 */
- (LeapHand *)hand;
@property (nonatomic, weak, getter = hand, readonly)LeapHand *hand;
/**
 * Returns an invalid LeapPointable object.
 *
 * You can use the instance returned by this function in comparisons testing
 * whether a given LeapPointable instance is valid or invalid. (You can also use the
 * LeapPointable isValid function.)
 *
 * @returns The invalid LeapPointable instance.
 */
+ (LeapPointable *)invalid;

@end

//////////////////////////////////////////////////////////////////////////
//FINGER
/**
 * The LeapFinger class represents a tracked finger.
 *
 * Fingers are pointable objects that the Leap has classified as a finger.
 * Get valid LeapFinger objects from a <LeapFrame> or a <LeapHand> object.
 *
 * Note that LeapFinger objects can be invalid, which means that they do not contain
 * valid tracking data and do not correspond to a physical finger. Invalid LeapFinger
 * objects can be the result of asking for a finger using an ID from an
 * earlier frame when no fingers with that ID exist in the current frame.
 * A LeapFinger object created from the LeapFinger constructor is also invalid.
 * Test for validity with the LeapFinger isValid function.
 */
@interface LeapFinger : LeapPointable
@end

//////////////////////////////////////////////////////////////////////////
//TOOL
/**
 * The LeapTool class represents a tracked tool.
 *
 * Tools are pointable objects that the Leap has classified as a tool.
 * Tools are longer, thinner, and straighter than a typical finger.
 * Get valid LeapTool objects from a <LeapFrame> or a <LeapHand> object.
 *
 * <img src="../docs/images/Leap_Tool.png"/>
 *
 * Note that LeapTool objects can be invalid, which means that they do not contain
 * valid tracking data and do not correspond to a physical tool. Invalid LeapTool
 * objects can be the result of asking for a tool object using an ID from an
 * earlier frame when no tools with that ID exist in the current frame.
 * A LeapTool object created from the LeapTool constructor is also invalid.
 * Test for validity with the LeapTool isValid function.
 */
@interface LeapTool : LeapPointable
@end

//////////////////////////////////////////////////////////////////////////
//HAND
/**
 * The LeapHand class reports the physical characteristics of a detected hand.
 *
 * Hand tracking data includes a palm position and velocity; vectors for
 * the palm normal and direction to the fingers; properties of a sphere fit
 * to the hand; and lists of the attached fingers and tools.
 *
 * Note that LeapHand objects can be invalid, which means that they do not contain
 * valid tracking data and do not correspond to a physical entity. Invalid LeapHand
 * objects can be the result of asking for a Hand object using an ID from an
 * earlier frame when no hand objects with that ID exist in the current frame.
 * A hand object created from the LeapHand constructor is also invalid.
 * Test for validity with the LeapHand isValid function.
 */
@interface LeapHand : NSObject

- (NSString *)description;
/**
 * A unique ID assigned to this LeapHand object, whose value remains the same
 * across consecutive frames while the tracked hand remains visible. 
 * 
 * If tracking is lost (for example, when a hand is occluded by another hand
 * or when it is withdrawn from or reaches the edge of the Leap field of view),
 * the Leap may assign a new ID when it detects the hand in a future frame.
 *
 * Use the ID value with the <[LeapFrame hand:]> function to find this LeapHand object
 * in future frames.
 *
 * @returns The ID of this hand.
 */
- (int32_t)id;
@property (nonatomic, getter = id, readonly)int32_t id;
/**
 * The list of <LeapPointable> objects (fingers and tools) detected in this frame
 * that are associated with this hand, given in arbitrary order. 
 *
 * The list can be empty if no fingers or tools associated with this hand 
 * are detected.
 *
 * Use the <[LeapPointable isFinger]> function to determine whether or not an
 * item in the list represents a finger. Use the <[LeapPointable isTool]> function
 * to determine whether or not an item in the list represents a tool.
 * You can also get only fingers using the <[LeapHand fingers]> function or
 * only tools using the <[LeapHand tools]> function.
 *
 * @returns An NSArray containing all <LeapPointable> objects associated with this hand.
 */
- (NSArray *)pointables;
@property (nonatomic, getter = pointables, readonly)NSArray *pointables;
/**
 * The list of <LeapFinger> objects detected in this frame that are attached to
 * this hand, given in arbitrary order.
 *
 * The list can be empty if no fingers attached to this hand are detected.
 *
 * @returns An NSArray containing all <LeapFinger> objects attached to this hand.
 */
- (NSArray *)fingers;
@property (nonatomic, getter = fingers, readonly)NSArray *fingers;
/**
 * The list of <LeapTool> objects detected in this frame that are held by this
 * hand, given in arbitrary order.
 * The list can be empty if no tools held by this hand are detected.
 *
 * @returns An NSArray containing all <LeapTool> objects held by this hand.
 */
- (NSArray *)tools;
@property (nonatomic, getter = tools, readonly)NSArray *tools;
/**
 * The <LeapPointable> object with the specified ID associated with this hand.
 *
 * Use this [LeapHand pointable:] function to retrieve a LeapPointable object
 * associated with this hand using an ID value obtained from a previous frame.
 * This function always returns a LeapPointable object, but if no finger or tool
 * with the specified ID is present, an invalid LeapPointable object is returned.
 *
 * Note that ID values persist across frames, but only until tracking of a
 * particular object is lost. If tracking of a finger or tool is lost and subsequently
 * regained, the new LeapPointable object representing that finger or tool may have a
 * different ID than that representing the finger or tool in an earlier frame.
 *
 * @param pointableId The ID value of a <LeapPointable> object from a previous frame.
 * @returns The <LeapPointable> object with the matching ID if one exists for this
 * hand in this frame; otherwise, an invalid LeapPointable object is returned.
 */
- (LeapPointable *)pointable:(int32_t)pointableId;
/**
 * The <LeapFinger> object with the specified ID attached to this hand.
 *
 * Use this [LeapHand finger:] function to retrieve a LeapFinger object attached to
 * this hand using an ID value obtained from a previous frame.
 * This function always returns a LeapFinger object, but if no finger
 * with the specified ID is present, an invalid LeapFinger object is returned.
 *
 * Note that ID values persist across frames, but only until tracking of a
 * particular object is lost. If tracking of a finger is lost and subsequently
 * regained, the new LeapFinger object representing that finger may have a
 * different ID than that representing the finger in an earlier frame.
 *
 * @param fingerId The ID value of a <LeapFinger> object from a previous frame.
 * @returns The <LeapFinger> object with the matching ID if one exists for this
 * hand in this frame; otherwise, an invalid LeapFinger object is returned.
 */
- (LeapFinger *)finger:(int32_t)fingerId;
/**
 * The <LeapTool> object with the specified ID held by this hand.
 *
 * Use this [LeapHand tool:] function to retrieve a LeapTool object held by
 * this hand using an ID value obtained from a previous frame.
 * This function always returns a LeapTool object, but if no tool
 * with the specified ID is present, an invalid LeapTool object is returned.
 *
 * Note that ID values persist across frames, but only until tracking of a
 * particular object is lost. If tracking of a tool is lost and subsequently
 * regained, the new LeapTool object representing that tool may have a
 * different ID than that representing the tool in an earlier frame.
 *
 * @param toolId The ID value of a <LeapTool> object from a previous frame.
 * @returns The <LeapTool> object with the matching ID if one exists for this
 * hand in this frame; otherwise, an invalid LeapTool object is returned.
 */
- (LeapTool *)tool:(int32_t)toolId;
/**
 * The center position of the palm in millimeters from the Leap origin.
 *
 * @returns The <LeapVector> representing the coordinates of the palm position.
 */
- (LeapVector *)palmPosition;
@property (nonatomic, getter = palmPosition, readonly)LeapVector *palmPosition;
/**
 * The rate of change of the palm position in millimeters/second.
 *
 * @returns The <LeapVector> representing the coordinates of the palm velocity.
 */
- (LeapVector *)palmVelocity;
@property (nonatomic, getter = palmVelocity, readonly)LeapVector *palmVelocity;
/**
 * The normal vector to the palm. If your hand is flat, this vector will
 * point downward, or "out" of the front surface of your palm.
 *
 * <img src="../docs/images/Leap_Palm_Vectors.png"/>
 *
 * The direction is expressed as a unit vector pointing in the same
 * direction as the palm normal (that is, a vector orthogonal to the palm).
 *
 * @returns The <LeapVector> normal to the plane formed by the palm.
 */
- (LeapVector *)palmNormal;
@property (nonatomic, getter = palmNormal, readonly)LeapVector *palmNormal;
/**
 * The direction from the palm position toward the fingers.
 *
 * The direction is expressed as a unit vector pointing in the same
 * direction as the directed line from the palm position to the fingers.
 *
 * @returns The <LeapVector> pointing from the palm position toward the fingers.
 */
- (LeapVector *)direction;
@property (nonatomic, getter = direction, readonly)LeapVector *direction;
/**
 * The center of a sphere fit to the curvature of this hand.
 *
 * This sphere is placed roughly as if the hand were holding a ball.
 *
 * <img src="../docs/images/Leap_Hand_Ball.png"/>
 *
 * @returns The <LeapVector> representing the center position of the sphere.
 */
- (LeapVector *)sphereCenter;
@property (nonatomic, getter = sphereCenter, readonly)LeapVector *sphereCenter;
/**
 * The radius of a sphere fit to the curvature of this hand.
 *
 * This sphere is placed roughly as if the hand were holding a ball. Thus the
 * size of the sphere decreases as the fingers are curled into a fist.
 * @returns The radius of the sphere in millimeters.
 */
- (float)sphereRadius;
@property (nonatomic, getter = sphereRadius, readonly)float sphereRadius;
/**
 * Reports whether this is a valid LeapHand object.
 *
 * @returns YES, if this LeapHand object contains valid tracking data.
 */
- (BOOL)isValid;
@property (nonatomic, getter = isValid, readonly)BOOL isValid;
/**
 * The <LeapFrame> associated with this Hand.
 *
 * @returns The associated <LeapFrame> object, if available; otherwise,
 * an invalid LeapFrame object is returned.
 */
- (LeapFrame *)frame;
@property (nonatomic, weak, getter = frame, readonly)LeapFrame *frame;
/**
 * The change of position of this hand between the current <LeapFrame> and
 * the specified LeapFrame.
 *
 * The returned translation vector provides the magnitude and direction of
 * the movement in millimeters.
 *
 * If a corresponding Hand object is not found in sinceFrame, or if either
 * this frame or sinceFrame are invalid LeapFrame objects, then this method
 * returns a zero vector.
 *
 * @param sinceFrame The starting <LeapFrame> for computing the translation.
 * @returns A <LeapVector> representing the heuristically determined change in
 * hand position between the current frame and that specified in the
 * sinceFrame parameter.
 */
- (LeapVector *)translation:(const LeapFrame *)sinceFrame;
/**
 * The axis of rotation derived from the change in orientation of this
 * hand, and any associated fingers and tools, between the current <LeapFrame>
 * and the specified LeapFrame.
 *
 * The returned direction vector is normalized.
 *
 * If a corresponding LeapHand object is not found in sinceFrame, or if either
 * this frame or sinceFrame are invalid LeapFrame objects, then this method
 * returns a zero vector.
 *
 * @param sinceFrame The starting <LeapFrame> for computing the relative rotation.
 * @returns A <LeapVector> containing the normalized direction vector representing the heuristically
 * determined axis of rotational change of the hand between the current
 * frame and that specified in the sinceFrame parameter.
 */
- (LeapVector *)rotationAxis:(const LeapFrame *)sinceFrame;
/**
 * The angle of rotation around the rotation axis derived from the change
 * in orientation of this hand, and any associated fingers and tools,
 * between the current <LeapFrame> and the specified LeapFrame.
 *
 * The returned angle is expressed in radians measured clockwise around the
 * rotation axis (using the right-hand rule) between the start and end frames.
 * The value is always between 0 and pi radians (0 and 180 degrees).
 *
 * If a corresponding LeapHand object is not found in sinceFrame, or if either
 * this frame or sinceFrame are invalid LeapFrame objects, then the angle of
 * rotation is zero.
 *
 * @param sinceFrame The starting <LeapFrame> for computing the relative rotation.
 * @returns A positive value representing the heuristically determined
 * rotational change of the hand between the current frame and that
 * specified in the sinceFrame parameter.
 */
- (float)rotationAngle:(const LeapFrame *)sinceFrame;
/**
 * The angle of rotation around the specified axis derived from the change
 * in orientation of this hand, and any associated fingers and tools,
 * between the current <LeapFrame> and the specified LeapFrame.
 *
 * The returned angle is expressed in radians measured clockwise around the
 * rotation axis (using the right-hand rule) between the start and end frames.
 * The value is always between -pi and pi radians (-180 and 180 degrees).
 *
 * If a corresponding LeapHand object is not found in sinceFrame, or if either
 * this frame or sinceFrame are invalid LeapFrame objects, then the angle of
 * rotation is zero.
 *
 * @param sinceFrame The starting <LeapFrame> for computing the relative rotation.
 * @param axis A <LeapVector> representing the axis to measure rotation around.
 * @returns A value representing the heuristically determined rotational
 * change of the hand between the current frame and that specified in the
 * sinceFrame parameter around the specified axis.
 */
- (float)rotationAngle:(const LeapFrame *)sinceFrame axis:(const LeapVector *)axis;
/**
 * The transform matrix expressing the rotation derived from the change
 * in orientation of this hand, and any associated fingers and tools,
 * between the current <LeapFrame> and the specified LeapFrame.
 *
 * If a corresponding LeapHand object is not found in sinceFrame, or if either
 * this frame or sinceFrame are invalid LeapFrame objects, then this method
 * returns an identity matrix.
 *
 * @param sinceFrame The starting <LeapFrame> for computing the relative rotation.
 * @returns A transformation <LeapMatrix> representing the heuristically determined
 * rotational change of the hand between the current frame and that specified
 * in the sinceFrame parameter.
 */
- (LeapMatrix *)rotationMatrix:(const LeapFrame *)sinceFrame;
/**
 * The scale factor derived from this hand's motion between the current <LeapFrame>
 * and the specified LeapFrame.
 *
 * The scale factor is always positive. A value of 1.0 indicates no
 * scaling took place. Values between 0.0 and 1.0 indicate contraction
 * and values greater than 1.0 indicate expansion.
 *
 * The Leap derives scaling from the relative inward or outward motion of
 * a hand and its associated fingers and tools (independent of translation
 * and rotation).
 *
 * If a corresponding LeapHand object is not found in sinceFrame, or if either
 * this frame or sinceFrame are invalid LeapFrame objects, then this method
 * returns 1.0.
 *
 * @param sinceFrame The starting <LeapFrame> for computing the relative scaling.
 * @returns A positive value representing the heuristically determined
 * scaling change ratio of the hand between the current frame and that
 * specified in the sinceFrame parameter.
 */
- (float)scaleFactor:(const LeapFrame *)sinceFrame;
/**
 * Returns an invalid LeapHand object.
 *
 * You can use the instance returned by this function in comparisons testing
 * whether a given LeapHand instance is valid or invalid. (You can also use the
 * LeapHand isValid: function.)
 *
 * @returns The invalid LeapHand instance.
 */
+ (LeapHand *)invalid;

@end


//////////////////////////////////////////////////////////////////////////
//SCREEN
/**
 * The LeapScreen class represents a computer monitor screen.
 *
 * The LeapScreen class reports characteristics describing the position and
 * orientation of the monitor screen within the Leap coordinate system. These
 * characteristics include the bottom-left corner position of the screen,
 * direction vectors for the horizontal and vertical axes of the screen, and
 * the screen's normal vector. The screen must be properly registered with the
 * Screen Locator for the Leap to report these characteristics accurately.
 * The LeapScreen class also reports the size of the screen in pixels, using
 * information obtained from the operating system. (Run the Screen Locator
 * from the Leap Application Settings dialog, on the Screen page.)
 *
 * You can get the point of intersection between the screen and a ray
 * projected from a <LeapPointable> object using the LeapScreen 
 * intersect:normalize:clampRatio function.
 * Likewise, you can get the distance to the closest point on the screen to a point in space
 * using the LeapScreen distanceToPoint: function. Again, the screen location
 * must be registered with the Screen Locator for these functions to
 * return accurate values.
 *
 * Note that LeapScreen objects can be invalid, which means that they do not contain
 * valid screen coordinate data and do not correspond to a physical entity.
 * Test for validity with the LeapScreen isValid: function.
 */
@interface LeapScreen : NSObject

- (NSString *)description;
/**
 * A unique identifier for this screen based on the screen
 * information in the configuration. A default screen with ID, *0*,
 * always exists and contains default characteristics, even if no screens
 * have been located.
 */
- (int32_t)id;
@property (nonatomic, getter = id, readonly)int32_t id;
/**
 * Returns the intersection between this screen and a ray projecting from a
 * Pointable object.
 *
 * The projected ray emanates from the <[LeapPointable tipPosition]> along the
 * pointable's direction vector.
 *
 * Set the normalize parameter to true to request the intersection point in
 * normalized screen coordinates. Normalized screen coordinates are usually
 * values between 0 and 1, where 0 represents the screen's origin at the
 * bottom-left corner and 1 represents the opposite edge (either top or
 * right). When you request normalized coordinates, the z-component of the
 * returned vector is zero. Multiply a normalized coordinate by the values
 * returned by <[LeapScreen widthPixels]> or <[LeapScreen heightPixels]> to calculate
 * the screen position in pixels (remembering that many other computer
 * graphics coordinate systems place the origin in the top-left corner).
 *
 * Set the normalize parameter to false to request the intersection point
 * in Leap coordinates (millimeters from the Leap origin).
 *
 * If the LeapPointable object points outside the screen's border (but still
 * intersects the plane in which the screen lies), the returned intersection
 * point is clamped to the nearest point on the edge of the screen.
 *
 * You can use the clampRatio parameter to contract or expand the area in
 * which you can point. For example, if you set the clampRatio parameter to
 * 0.5, then the positions reported for intersection points outside the
 * central 50% of the screen are moved to the border of this smaller area.
 * If, on the other hand, you expanded the area by setting clampRatio to
 * a value such as 3.0, then you could point well outside screen's physical
 * boundary before the intersection points would be clamped. The positions
 * for any points clamped would also be placed on this larger outer border.
 * The positions reported for any intersection points inside the clamping
 * border are unaffected by clamping.
 *
 * If the LeapPointable object does not point toward the plane of the screen
 * (i.e. it is pointing parallel to or away from the screen), then the
 * components of the returned vector are all set to NaN (not-a-number).
 *
 * @param pointable The <LeapPointable> object to check for screen intersection.
 *
 * @param normalize If true, return normalized coordinates representing
 * the intersection point as a percentage of the screen's width and height.
 * If false, return Leap coordinates (millimeters from the Leap origin,
 * which is located at the center of the top surface of the Leap device).
 * If true and the clampRatio parameter is set to 1.0, coordinates will be
 * of the form (0..1, 0..1, 0). Setting the clampRatio to a different value
 * changes the range for normalized coordinates. For example, a clampRatio
 * of 5.0 changes the range of values to be of the form (-2..3, -2..3, 0).
 *
 * @param clampRatio Adjusts the clamping border around this screen.
 * By default this ratio is 1.0, and the border corresponds to the actual
 * boundaries of the screen. Setting clampRatio to 0.5 would reduce the
 * interaction area. Likewise, setting the ratio to 2.0 would increase the
 * interaction area, adding 50% around each edge of the physical monitor.
 * Intersection points outside the interaction area are repositioned to
 * the closest point on the clamping border before the vector is returned.
 *
 * @returns A <LeapVector> containing the coordinates of the intersection between
 * this screen and a ray projecting from the specified Pointable object.
 */
- (LeapVector *)intersect:(LeapPointable *)pointable normalize:(BOOL)normalize clampRatio:(float)clampRatio;

/**
 * Returns the intersection between this screen and a ray projecting from
 * the specified position along the specified direction.
 *
 * Set the normalize parameter to true to request the intersection point in
 * normalized screen coordinates. Normalized screen coordinates are usually
 * values between 0 and 1, where 0 represents the screen's origin at the
 * bottom-left corner and 1 represents the opposite edge (either top or
 * right). When you request normalized coordinates, the z-component of the
 * returned vector is zero. Multiply a normalized coordinate by the values
 * returned by <[LeapScreen widthPixels]> or <[LeapScreen heightPixels]> to calculate
 * the screen position in pixels (remembering that many other computer
 * graphics coordinate systems place the origin in the top-left corner).
 *
 * Set the normalize parameter to false to request the intersection point
 * in Leap coordinates (millimeters from the Leap origin).
 *
 * If the specified ray points outside the screen's border (but still
 * intersects the plane in which the screen lies), the returned intersection
 * point is clamped to the nearest point on the edge of the screen.
 *
 * You can use the clampRatio parameter to contract or expand the area in
 * which you can point. For example, if you set the clampRatio parameter to
 * 0.5, then the positions reported for intersection points outside the
 * central 50% of the screen are moved to the border of this smaller area.
 * If, on the other hand, you expanded the area by setting clampRatio to
 * a value such as 3.0, then you could point well outside screen's physical
 * boundary before the intersection points would be clamped. The positions
 * for any points clamped would also be placed on this larger outer border.
 * The positions reported for any intersection points inside the clamping
 * border are unaffected by clamping.
 *
 * If the specified ray does not point toward the plane of the screen
 * (i.e. it is pointing parallel to or away from the screen), then the
 * components of the returned vector are all set to NaN (not-a-number).
 *
 * @param position The position from which to check for screen intersection.
 * @param direction The direction in which to check for screen intersection.
 *
 * @param normalize If true, return normalized coordinates representing
 * the intersection point as a percentage of the screen's width and height.
 * If false, return Leap coordinates (millimeters from the Leap origin,
 * which is located at the center of the top surface of the Leap device).
 * If true and the clampRatio parameter is set to 1.0, coordinates will be
 * of the form (0..1, 0..1, 0). Setting the clampRatio to a different value
 * changes the range for normalized coordinates. For example, a clampRatio
 * of 5.0 changes the range of values to be of the form (-2..3, -2..3, 0).
 *
 * @param clampRatio Adjusts the clamping border around this screen.
 * By default this ratio is 1.0, and the border corresponds to the actual
 * boundaries of the screen. Setting clampRatio to 0.5 would reduce the
 * interaction area. Likewise, setting the ratio to 2.0 would increase the
 * interaction area, adding 50% around each edge of the physical monitor.
 * Intersection points outside the interaction area are repositioned to
 * the closest point on the clamping border before the vector is returned.
 *
 * @returns A Vector containing the coordinates of the intersection between
 * this screen and a ray projecting from the specified position in the
 * specified direction.
 */
- (LeapVector *)intersect:(const LeapVector *)position direction:(const LeapVector *)direction normalize:(BOOL)normalize clampRatio:(float)clampRatio;

/**
 * Returns the projection from the specified position onto this screen.
 *
 * Set the normalize parameter to true to request the projection point in
 * normalized screen coordinates. Normalized screen coordinates are usually
 * values between 0 and 1, where 0 represents the screen's origin at the
 * bottom-left corner and 1 represents the opposite edge (either top or
 * right). When you request normalized coordinates, the z-component of the
 * returned vector is zero. Multiply a normalized coordinate by the values
 * returned by <[LeapScreen widthPixels]> or <[LeapScreen heightPixels]> to calculate
 * the screen position in pixels (remembering that many other computer
 * graphics coordinate systems place the origin in the top-left corner).
 *
 * Set the normalize parameter to false to request the projection point
 * in Leap coordinates (millimeters from the Leap origin).
 *
 * If the specified point projects outside the screen's border, the returned
 * projection point is clamped to the nearest point on the edge of the screen.
 *
 * You can use the clampRatio parameter to contract or expand the area in
 * which you can point. For example, if you set the clampRatio parameter to
 * 0.5, then the positions reported for projection points outside the
 * central 50% of the screen are moved to the border of this smaller area.
 * If, on the other hand, you expanded the area by setting clampRatio to
 * a value such as 3.0, then you could point well outside screen's physical
 * boundary before the projection points would be clamped. The positions
 * for any points clamped would also be placed on this larger outer border.
 * The positions reported for any projection points inside the clamping
 * border are unaffected by clamping.
 *
 * @param position The position from which to project onto this screen.
 *
 * @param normalize If true, return normalized coordinates representing
 * the projection point as a percentage of the screen's width and height.
 * If false, return Leap coordinates (millimeters from the Leap origin,
 * which is located at the center of the top surface of the Leap device).
 * If true and the clampRatio parameter is set to 1.0, coordinates will be
 * of the form (0..1, 0..1, 0). Setting the clampRatio to a different value
 * changes the range for normalized coordinates. For example, a clampRatio
 * of 5.0 changes the range of values to be of the form (-2..3, -2..3, 0).
 *
 * @param clampRatio Adjusts the clamping border around this screen.
 * By default this ratio is 1.0, and the border corresponds to the actual
 * boundaries of the screen. Setting clampRatio to 0.5 would reduce the
 * interaction area. Likewise, setting the ratio to 2.0 would increase the
 * interaction area, adding 50% around each edge of the physical monitor.
 * Projection points outside the interaction area are repositioned to
 * the closest point on the clamping border before the vector is returned.
 *
 * @returns A Vector containing the coordinates of the projection between
 * this screen and a ray projecting from the specified position onto the
 * screen along its normal vector.
 */
- (LeapVector *)project:(LeapVector *)position normalize:(BOOL)normalize clampRatio:(float)clampRatio;
/**
 * A <LeapVector> representing the horizontal axis of this LeapScreen within the
 * Leap coordinate system.
 *
 * The magnitude of this vector estimates the physical width of this LeapScreen
 * in millimeters. The direction of this vector is parallel to the bottom
 * edge of the screen and points toward the right edge of the screen.
 *
 * Together, horizontalAxis, verticalAxis, and bottomLeftCorner
 * describe the physical position, size and orientation of this LeapScreen.
 *
 * @returns A <LeapVector> representing the bottom, horizontal edge of this LeapScreen.
 */
- (LeapVector *)horizontalAxis;
@property (nonatomic, getter = horizontalAxis, readonly)LeapVector *horizontalAxis;
/**
 * A <LeapVector> representing the vertical axis of this LeapScreen within the
 * Leap coordinate system.
 *
 * The magnitude of this vector estimates the physical height of this LeapScreen
 * in millimeters. The direction of this vector is parallel to the left
 * edge of the screen and points toward the top edge of the screen.
 *
 * Together, horizontalAxis, verticalAxis, and bottomLeftCorner
 * describe the physical position, size and orientation of this screen.
 *
 * @returns A <LeapVector> representing the left, vertical edge of this LeapScreen.
 */
- (LeapVector *)verticalAxis;
@property (nonatomic, getter = verticalAxis, readonly)LeapVector *verticalAxis;
/**
 * A <LeapVector> representing the bottom left corner of this LeapScreen within the
 * Leap coordinate system.
 *
 * The point represented by this vector defines the origin of the screen
 * in the Leap coordinate system.
 *
 * Together, horizontalAxis, verticalAxis, and bottomLeftCorner
 * describe the physical position, size and orientation of this LeapScreen.
 *
 * @returns A <LeapVector> containing the coordinates of the bottom-left corner
 * of this LeapScreen.
 */
- (LeapVector *)bottomLeftCorner;
@property (nonatomic, getter = bottomLeftCorner, readonly)LeapVector *bottomLeftCorner;
/**
 * A <LeapVector> normal to the plane in which this LeapScreen lies.
 *
 * The normal vector is a unit direction vector orthogonal to the screen's
 * surface plane. It points toward a viewer positioned for typical use of
 * the monitor.
 *
 * @returns A <LeapVector> representing this LeapScreen's normal vector.
 */
- (LeapVector *)normal;
@property (nonatomic, getter = normal, readonly)LeapVector *normal;
/**
 * The horizontal resolution of this screen, in pixels.
 *
 * @returns The width of this LeapScreen in pixels.
 */
- (int)widthPixels;
@property (nonatomic, getter = widthPixels, readonly)int widthPixels;
/**
 * The vertical resolution of this screen, in pixels.
 *
 * @returns The height of this LeapScreen in pixels.
 */
- (int)heightPixels;
@property (nonatomic, getter = heightPixels, readonly)int heightPixels;
/**
 * The shortest distance from the specified point to the plane in which this
 * LeapScreen lies.
 *
 * @param point The point of interest.
 * @returns The length of the perpendicular line segment extending from
 * the plane this LeapScreen lies in to the specified point.
 */
- (float)distanceToPoint:(const LeapVector *)point;
/**
 * Reports whether this is a valid LeapScreen object.
 *
 * **Important:** A valid LeapScreen object does not necessarily contain
 * up-to-date screen location information. Location information is only
 * accurate until the Leap device or the monitor are moved. In addition, the
 * primary screen always contains default location information even if the
 * user has never run the screen location utility. This default location
 * information will not return accurate results.
 *
 * @returns YES, if this LeapScreen object contains valid data.
 */
- (BOOL)isValid;
@property (nonatomic, getter = isValid, readonly)BOOL isValid;
/**
 * Compare LeapScreen object equality.
 * Two LeapScreen objects are equal if and only if both objects represent the
 * exact same screens and both LeapScreen objects are valid.
 * @param other The LeapScreen object to compare.
 */
- (BOOL)equals:(const LeapScreen *)other;
// not provided: not_equals
// user should emulate with !scr.equals(...)
/**
 * Returns an invalid LeapScreen object.
 *
 * You can use the instance returned by this function in comparisons testing
 * whether a given LeapScreen instance is valid or invalid. (You can also use the
 * LeapScreen isValid function.)
 *
 * @returns The invalid LeapScreen instance.
 */
+ (LeapScreen *)invalid;

@end

//////////////////////////////////////////////////////////////////////////
// SCREENLIST Category
/**
 * The LeapScreenList category supplies methods for getting a screen from
 * an NSArray containing <LeapScreen> objects based on the relationship between
 * the screen and a Pointable object or point.
 */
@interface NSArray (LeapScreenList)
/**
 * Gets the closest <LeapScreen> intercepting a ray projecting from the specified
 * Pointable object.
 *
 * The projected ray emanates from the Pointable tipPosition along the
 * Pointable's direction vector. If the projected ray does not intersect
 * any screen surface directly, then the Leap checks for intersection with
 * the planes extending from the surfaces of the known screens
 * and returns the LeapScreen with the closest intersection.
 *
 * If no intersections are found (i.e. the ray is directed parallel to or
 * away from all known screens), then an invalid LeapScreen object is returned.
 *
 * *Note:* Be sure to test whether the LeapScreen object returned by this method
 * is valid. Attempting to use an invalid LeapScreen object will lead to
 * incorrect results.
 *
 * @param pointable The <LeapPointable> object to check for screen intersection.
 * @returns The closest <<LeapScreen>> toward which the specified LeapPointable object
 * is pointing, or, if the pointable is not pointing in the direction of
 * any known screen, an invalid LeapScreen object.
 */
- (LeapScreen *)closestScreenHit:(LeapPointable *)pointable;
/**
 * Gets the closest <LeapScreen> intercepting a ray projecting from the specified
 * position in the specified direction.
 *
 * The projected ray emanates from the position along the direction vector.
 * If the projected ray does not intersect any screen surface directly,
 * then the Leap checks for intersection with the planes extending from the
 * surfaces of the known screens and returns the LeapScreen with the closest
 * intersection.
 *
 * If no intersections are found (i.e. the ray is directed parallel to or
 * away from all known screens), then an invalid LeapScreen object is returned.
 *
 * *Note:* Be sure to test whether the LeapScreen object returned by this method
 * is valid. Attempting to use an invalid LeapScreen object will lead to
 * incorrect results.
 *
 * @param position The position from which to check for screen intersection.
 * @param direction The direction in which to check for screen intersection.
 * @returns The closest <LeapScreen> toward which the specified ray is pointing,
 * or, if the ray is not pointing in the direction of any known screen,
 * an invalid LeapScreen object.
 */
- (LeapScreen *)closestScreenHit:(const LeapVector *)position direction:(const LeapVector *)direction;
/**
 * Gets the <LeapScreen> closest to the specified position.
 *
 * The specified position is projected along each screen's normal vector
 * onto the screen's plane. The screen whose projected point is closest to
 * the specified position is returned. Call <[LeapScreen project:normalize:clampRatio:]>
 * on the returned LeapScreen object to find the projected point.
 *
 * @param position The position from which to check for screen projection.
 * @returns The closest <LeapScreen> onto which the specified position is projected.
 */
- (LeapScreen *)closestScreen:(LeapVector *)position;
@end

//////////////////////////////////////////////////////////////////////////
//GESTURE
/**
 * The LeapGesture class represents a recognized movement by the user.
 *
 * The Leap watches the activity within its field of view for certain movement
 * patterns typical of a user gesture or command. For example, a movement from side to
 * side with the hand can indicate a swipe gesture, while a finger poking forward
 * can indicate a screen tap gesture.
 *
 * When the Leap recognizes a gesture, it assigns an ID and adds a
 * LeapGesture object to the frame gesture list. For continuous gestures, which
 * occur over many frames, the Leap updates the gesture by adding
 * a LeapGesture object having the same ID and updated properties in each
 * subsequent frame.
 *
 * **Important:** Recognition for each type of gesture must be enabled using the
 * <[LeapController enableGesture:enable:]> function; otherwise **no gestures are
 * recognized or reported**.
 *
 * Subclasses of LeapGesture define the properties for the specific movement patterns
 * recognized by the Leap.
 *
 * The LeapGesture subclasses for include:
 *
 * * <LeapCircleGesture> -- A circular movement by a finger.
 * * <LeapSwipeGesture> -- A straight line movement by the hand with fingers extended.
 * * <LeapScreenTapGesture> -- A forward tapping movement by a finger.
 * * <LeapKeyTapGesture> -- A downward tapping movement by a finger.
 *
 * Circle and swipe gestures are continuous and these objects can have a
 * state of start, update, and stop.
 *
 * The tap gestures are discrete. The Leap only creates a single
 * LeapScreenTapGesture or LeapKeyTapGesture object appears for each tap and that 
 * object is always assigned the stop state.
 *
 * Get valid LeapGesture instances from a <LeapFrame> object. You can get a list of gestures
 * with the <[LeapFrame gestures:]> method. You can also
 * use the <[LeapFrame gesture:]> method to find a gesture in the current frame using
 * an ID value obtained in a previous frame.
 *
 * LeapGesture objects can be invalid. For example, when you get a gesture by ID
 * using `[LeapFrame gesture:]`, and there is no gesture with that ID in the current
 * frame, then `gesture:` returns an Invalid LeapGesture object (rather than a null
 * value). Always check object validity in situations where a gesture might be
 * invalid.
 */
@interface LeapGesture : NSObject
/**
 * The <LeapFrame> containing this LeapGesture instance.
 *
 * @return The parent <LeapFrame> object.
 */
@property (nonatomic, strong, readonly)LeapFrame *frame;
/**
 * The list of hands associated with this LeapGesture, if any.
 *
 * If no hands are related to this gesture, the list is empty.
 *
 * @return NSArray the list of related <LeapHand> objects.
 */
@property (nonatomic, strong, readonly)NSArray *hands;
/**
 * The list of fingers and tools associated with this LeapGesture, if any.
 *
 * If no <LeapPointable> objects are related to this gesture, the list is empty.
 *
 * @return NSArray the list of related <LeapPointable> objects.
 */
@property (nonatomic, strong, readonly)NSArray *pointables;

- (NSString *)description;
/**
 * The gesture type.
 *
 *
 * The supported types of gestures are defined by the LeapGestureType enumeration:
 *
 * * LEAP_GESTURE_TYPE_INVALID -- An invalid type.
 * * LEAP_GESTURE_TYPE_SWIPE  -- A straight line movement by the hand with fingers extended.
 * * LEAP_GESTURE_TYPE_CIRCLE -- A circular movement by a finger.
 * * LEAP_GESTURE_TYPE_SCREEN_TAP -- A forward tapping movement by a finger.
 * * LEAP_GESTURE_TYPE_KEY_TAP -- A downward tapping movement by a finger.
 *
 * @returns LeapGestureType A value from the LeapGestureType enumeration.
 */
- (LeapGestureType)type;
@property (nonatomic, getter = type, readonly)LeapGestureType type;
/**
 * The gesture state.
 *
 * Recognized movements occur over time and have a beginning, a middle,
 * and an end. The 'state' attribute reports where in that sequence this
 * LeapGesture object falls.
 *
 * The possible gesture states are defined by the LeapGestureState enumeration:
 *
 * * LEAP_GESTURE_STATE_INVALID -- An invalid state.
 * * LEAP_GESTURE_STATE_START -- The gesture is starting. Just enough has happened to recognize it.
 * * LEAP_GESTURE_STATE_UPDATE -- The gesture is in progress. (Note: not all gestures have updates).
 * * LEAP_GESTURE_STATE_STOP -- The gesture has completed or stopped.
 *
 * @returns LeapGestureState A value from the LeapGestureState enumeration.
 */
- (LeapGestureState)state;
@property (nonatomic, getter = state, readonly)LeapGestureState state;
/**
 * The gesture ID.
 *
 * All LeapGesture objects belonging to the same recognized movement share the
 * same ID value. Use the ID value with the <[LeapFrame gesture:]> method to
 * find updates related to this LeapGesture object in subsequent frames.
 *
 * @returns int32_t the ID of this LeapGesture.
 */
- (int32_t)id;
@property (nonatomic, getter = id, readonly)int32_t id;
/**
 * The elapsed duration of the recognized movement up to the
 * frame containing this LeapGesture object, in microseconds.
 *
 * The duration reported for the first LeapGesture in the sequence (with the
 * LEAP_GESTURE_STATE_START state) will typically be a small positive number since
 * the movement must progress far enough for the Leap to recognize it as
 * an intentional gesture.
 *
 * @return int64_t the elapsed duration in microseconds.
 */
- (int64_t)duration;
@property (nonatomic, getter = duration, readonly)int64_t duration;
/**
 * The elapsed duration in seconds.
 * @see duration
 * @return float the elapsed duration in seconds.
 */
- (float)durationSeconds;
@property (nonatomic, getter = durationSeconds, readonly)float durationSeconds;
/**
 * Reports whether this LeapGesture instance represents a valid gesture.
 *
 * An invalid LeapGesture object does not represent a snapshot of a recognized
 * movement. Invalid LeapGesture objects are returned when a valid object cannot
 * be provided. For example, when you get an gesture by ID
 * using <[LeapFrame gesture:]>, and there is no gesture with that ID in the current
 * frame, then `gesture:` returns an Invalid LeapGesture object (rather than a null
 * value). Always check object validity in situations where an gesture might be
 * invalid.
 *
 * @returns bool Yes, if this is a valid LeapGesture instance; NO, otherwise.
 */
- (BOOL)isValid;
@property (nonatomic, getter = isValid, readonly)BOOL isValid;
/**
 * Compare LeapGesture object equality.
 *
 * Two LeapGestures are equal if they represent the same snapshot of the same
 * recognized movement.
 * @param other The LeapGesture object to compare.
 */
- (BOOL)equals:(const LeapGesture *)other;
// not provided: not_equals
// user should emulate with !scr.equals(...)
/**
 * Returns an invalid LeapGesture object.
 *
 * You can use the instance returned by this function in comparisons testing
 * whether a given LeapGesture instance is valid or invalid. (You can also use the
 * <[LeapGesture isValid]> function.)
 *
 * @returns The invalid LeapGesture instance.
 */
+ (LeapGesture *)invalid;

@end

////////////////////////////////////////////////////////////////////////
//SWIPE GESTURE
/**
 * The LeapSwipeGesture class represents a swiping motion of a finger or tool.
 *
 * <img src="../docs/images/Leap_Gesture_Swipe.png"/>
 *
 * **Important:** To use swipe gestures in your application, you must enable
 * recognition of the swipe gesture. You can enable recognition with:
 *
 *     `[controller enableGesture:LEAP_GESTURE_TYPE_SWIPE enable:YES];`
 *
 * Swipe gestures are continuous. The LeapSwipeGesture objects for the gesture have
 * three possible states:
 *
 * * LEAP_GESTURE_STATE_START -- The gesture has just started. 
 * * LEAP_GESTURE_STATE_UPDATE -- The swipe gesture is continuing.
 * * LEAP_GESTURE_STATE_STOP -- The swipe gesture is finished.
 */
@interface LeapSwipeGesture : LeapGesture

/**
 * The current position of the swipe.
 *
 * @returns <LeapVector> The current swipe position within the Leap frame of
 * reference, in mm.
 */
- (LeapVector *)position;
@property (nonatomic, getter = position, readonly)LeapVector *position;
/**
 * The position where the swipe began.
 *
 * @returns <LeapVector> The starting position within the Leap frame of
 * reference, in mm.
 */
- (LeapVector *)startPosition;
@property (nonatomic, getter = startPosition, readonly)LeapVector *startPosition;
/**
 * The unit direction vector parallel to the swipe motion.
 *
 * You can compare the components of the vector to classify the swipe as
 * appropriate for your application. For example, if you are using swipes
 * for two dimensional scrolling, you can compare the x and y values to
 * determine if the swipe is primarily horizontal or vertical.
 *
 * @returns <LeapVector> The unit direction vector representing the swipe
 * motion.
 */
- (LeapVector *)direction;
@property (nonatomic, getter = direction, readonly)LeapVector *direction;
/**
 * The swipe speed in mm/second.
 *
 * @returns float The speed of the finger performing the swipe gesture in
 * millimeters per second.
 */
- (float)speed;
@property (nonatomic, getter = speed, readonly)float speed;
/**
 * The finger or tool performing the swipe gesture.
 *
 * @returns A <LeapPointable> object representing the swiping finger
 * or tool.
 */
- (LeapPointable *)pointable;

@end

//////////////////////////////////////////////////////////////////////////
//CIRCLE GESTURE
/**
 * The LeapCircleGesture classes represents a circular finger movement.
 *
 * A circle movement is recognized when the tip of a finger draws a circle
 * within the Leap field of view.
 *
 * <img src="../docs/images/Leap_Gesture_Circle.png"/>
 *
 * **Important:** To use circle gestures in your application, you must enable
 * recognition of the circle gesture. You can enable recognition with:
 *
 *        `[controller enableGesture:LEAP_GESTURE_TYPE_CIRCLE enable:YES];`
 *
 * Circle gestures are continuous. The LeapCircleGesture objects for the gesture have
 * three possible states:
 *
 * * LEAP_GESTURE_STATE_START -- The circle gesture has just started. The movement has
 *  progressed far enough for the recognizer to classify it as a circle.
 * * LEAP_GESTURE_STATE_UPDATE -- The circle gesture is continuing.
 * * LEAP_GESTURE_STATE_STOP -- The circle gesture is finished.
 */
@interface LeapCircleGesture : LeapGesture

- (float)progress;
@property (nonatomic, getter = progress, readonly)float progress;
/**
 * The center point of the circle within the Leap frame of reference.
 *
 * @returns <LeapVector> The center of the circle in mm from the Leap origin.
 */
- (LeapVector *)center;
@property (nonatomic, getter = center, readonly)LeapVector *center;

/**
 * Returns the normal vector for the circle being traced.
 *
 * If you draw the circle clockwise, the normal vector points in the same
 * general direction as the pointable object drawing the circle. If you draw
 * the circle counterclockwise, the normal points back toward the
 * pointable. If the angle between the normal and the pointable object
 * drawing the circle is less than 90 degrees, then the circle is clockwise.
 *
 *
 *     `NSString* clockwiseness;`
 *     `if ([[[circleGesture pointable] direction] angleTo:[circleGesture normal]] <= LEAP_PI/4) {`
 *     `    clockwiseness = @"clockwise";`
 *     `}`
 *     `else {`
 *     `    clockwiseness = @"counterclockwise";`
 *     `}`
 *
 *
 * @return <LeapVector> the normal vector for the circle being traced
 */

- (LeapVector *)normal;
@property (nonatomic, getter = normal, readonly)LeapVector *normal;
/**
 * The radius of the circle.
 *
 * @returns The circle radius in mm.
 */
- (float)radius;
@property (nonatomic, getter = radius, readonly)float radius;
/**
 * The finger performing the circle gesture.
 *
 * @returns A <LeapPointable> object representing the circling finger.
 */
- (LeapPointable *)pointable;
@property (nonatomic, getter = pointable, readonly)LeapPointable *pointable;

@end

//////////////////////////////////////////////////////////////////////////
//SCREEN TAP GESTURE
/**
 * The LeapScreenTapGesture class represents a tapping gesture by a finger or tool.
 *
 * A screen tap gesture is recognized when the tip of a finger pokes forward
 * and then springs back to approximately the original postion, as if
 * tapping a vertical screen. The tapping finger must pause briefly before beginning the tap.
 *
 * <img src="../docs/images/Leap_Gesture_Tap2.png"/>
 *
 * **Important:** To use screen tap gestures in your application, you must enable
 * recognition of the screen tap gesture. You can enable recognition with:
 *
 *     `[controller enableGesture:LEAP_GESTURE_TYPE_SCREEN_TAP enable:YES];`
 *
 * LeapScreenTap gestures are discrete. The LeapScreenTapGesture object 
 * representing a tap always has the state, LEAP_GESTURE_STATE_STOP. Only one 
 * LeapScreenTapGesture object is created for each screen tap gesture recognized.
 */
@interface LeapScreenTapGesture : LeapGesture

/**
 * The position where the screen tap is registered.
 *
 * @return A <LeapVector> containing the coordinates of screen tap location.
 */
- (LeapVector *)position;
@property (nonatomic, getter = position, readonly)LeapVector *position;
/**
 * The direction of finger tip motion.
 *
 * @returns <LeapVector> A unit direction vector.
 */
- (LeapVector *)direction;
@property (nonatomic, getter = direction, readonly)LeapVector *direction;
/**
 * The progess value is always 1.0 for a screen tap gesture.
 *
 * @returns float The value 1.0.
 */
- (float)progress;
@property (nonatomic, getter = progress, readonly)float progress;
/**
 * The finger performing the screen tap gesture.
 *
 * @returns A <LeapPointable> object representing the tapping finger.
 */
- (LeapPointable *)pointable;
@property (nonatomic, getter = pointable, readonly)LeapPointable *pointable;

@end

//////////////////////////////////////////////////////////////////////////
//KEY TAP GESTURE
/**
 * The LeapKeyTapGesture class represents a tapping gesture by a finger or tool.
 *
 * A key tap gesture is recognized when the tip of a finger rotates down toward the
 * palm and then springs back to approximately the original postion, as if
 * tapping. The tapping finger must pause briefly before beginning the tap.
 *
 * <img src="../docs/images/Leap_Gesture_Tap.png"/>
 *
 * **Important:** To use key tap gestures in your application, you must enable
 * recognition of the key tap gesture. You can enable recognition with:
 *
 *     `[controller enableGesture:LEAP_GESTURE_TYPE_KEY_TAP enable:YES];`
 *
 * Key tap gestures are discrete. The LeapKeyTapGesture object representing a tap always
 * has the state, LEAP_GESTURE_STATE_STOP. Only one LeapKeyTapGesture object is 
 * created for each key tap gesture recognized.
 */
@interface LeapKeyTapGesture : LeapGesture

/**
 * The position where the key tap is registered.
 *
 * @return A <LeapVector> containing the coordinates of key tap location.
 */
- (LeapVector *)position;
@property (nonatomic, getter = position, readonly)LeapVector *position;
/**
 * The direction of finger tip motion.
 *
 * @returns <LeapVector> A unit direction vector.
 */
- (LeapVector *)direction;
@property (nonatomic, getter = direction, readonly)LeapVector *direction;
/**
 * The progess value is always 1.0 for a key tap gesture.
 *
 * @returns float The value 1.0.
 */
- (float)progress;
@property (nonatomic, getter = progress, readonly)float progress;
/**
 * The finger performing the key tap gesture.
 *
 * @returns A <LeapPointable> object representing the tapping finger.
 */
- (LeapPointable *)pointable;
@property (nonatomic, getter = pointable, readonly)LeapPointable *pointable;

@end

//////////////////////////////////////////////////////////////////////////
//FRAME
/**
 * The LeapFrame class represents a set of hand and finger tracking data detected
 * in a single frame.
 *
 * The Leap detects hands, fingers and tools within the tracking area, reporting
 * their positions, orientations and motions in frames at the Leap frame rate.
 *
 * Access LeapFrame objects through an instance of a <LeapController>. Implement a
 * <LeapListener> subclass to receive a callback event when a new LeapFrame is available.
 */
@interface LeapFrame : NSObject

/**
 * The list of <LeapHand> objects detected in this frame, given in arbitrary order.
 * The list can be empty if no hands are detected.
 *
 * @returns NSArray containing all <LeapHand> objects detected in this frame.
 */
@property (nonatomic, strong, readonly)NSArray *hands;
/**
 * The list of <LeapPointable> objects (fingers and tools) detected in this frame,
 * given in arbitrary order. The list can be empty if no fingers or tools are detected.
 *
 * @returns NSArray containing all <LeapPointable> objects detected in this frame.
 */
@property (nonatomic, strong, readonly)NSArray *pointables;
/**
 * The list of <LeapFinger> objects detected in this frame, given in arbitrary order.
 * The list can be empty if no fingers are detected.
 *
 * @returns NSArray containing all <LeapFinger> objects detected in this frame.
 */
@property (nonatomic, strong, readonly)NSArray *fingers;
/**
 * The list of <LeapTool> objects detected in this frame, given in arbitrary order.
 * The list can be empty if no tools are detected.
 *
 * @returns NSArray containing all <LeapTool> objects detected in this frame.
 */
@property (nonatomic, strong, readonly)NSArray *tools;

- (NSString *)description;
- (void *)interfaceFrame;
/**
 * A unique ID for this LeapFrame. Consecutive frames processed by the Leap
 * have consecutive increasing values.
 *
 * @returns The frame ID.
 */
- (int64_t)id;
@property (nonatomic, getter = id, readonly)int64_t id;
/**
 * The frame capture time in microseconds elapsed since the Leap started.
 *
 * @returns The timestamp in microseconds.
 */
- (int64_t)timestamp;
@property (nonatomic, getter = timestamp, readonly)int64_t timestamp;
/**
 * The <LeapHand> object with the specified ID in this frame.
 *
 * Use the [LeapFrame hand:] function to retrieve the LeapHand object from
 * this frame using an ID value obtained from a previous frame.
 * This function always returns a LeapHand object, but if no hand
 * with the specified ID is present, an invalid LeapHand object is returned.
 *
 * Note that ID values persist across frames, but only until tracking of a
 * particular object is lost. If tracking of a hand is lost and subsequently
 * regained, the new LeapHand object representing that physical hand may have
 * a different ID than that representing the physical hand in an earlier frame.
 *
 * @param handId The ID value of a <LeapHand> object from a previous frame.
 * @returns The <LeapHand> object with the matching ID if one exists in this frame;
 * otherwise, an invalid LeapHand object is returned.
 */
- (LeapHand *)hand:(int32_t)handId;
/**
 * The <LeapPointable> object with the specified ID in this frame.
 *
 * Use the [LeapFrame pointable:] function to retrieve the LeapPointable object from
 * this frame using an ID value obtained from a previous frame.
 * This function always returns a LeapPointable object, but if no finger or tool
 * with the specified ID is present, an invalid LeapPointable object is returned.
 *
 * Note that ID values persist across frames, but only until tracking of a
 * particular object is lost. If tracking of a finger or tool is lost and subsequently
 * regained, the new LeapPointable object representing that finger or tool may have
 * a different ID than that representing the finger or tool in an earlier frame.
 *
 * @param pointableId The ID value of a <LeapPointable> object from a previous frame.
 * @returns The <LeapPointable> object with the matching ID if one exists in this frame;
 * otherwise, an invalid LeapPointable object is returned.
 */
- (LeapPointable *)pointable:(int32_t)pointableId;
/**
 * The <LeapFinger> object with the specified ID in this frame.
 *
 * Use the [LeapFrame finger:] function to retrieve the LeapFinger object from
 * this frame using an ID value obtained from a previous frame.
 * This function always returns a LeapFinger object, but if no finger
 * with the specified ID is present, an invalid LeapFinger object is returned.
 *
 * Note that ID values persist across frames, but only until tracking of a
 * particular object is lost. If tracking of a finger is lost and subsequently
 * regained, the new LeapFinger object representing that physical finger may have
 * a different ID than that representing the finger in an earlier frame.
 *
 * @param fingerId The ID value of a <LeapFinger> object from a previous frame.
 * @returns The <LeapFinger> object with the matching ID if one exists in this frame;
 * otherwise, an invalid LeapFinger object is returned.
 */
- (LeapFinger *)finger:(int32_t)fingerId;
/**
 * The <LeapTool> object with the specified ID in this frame.
 *
 * Use the [LeapFrame tool:] function to retrieve the LeapTool object from
 * this frame using an ID value obtained from a previous frame.
 * This function always returns a LeapTool object, but if no tool
 * with the specified ID is present, an invalid LeapTool object is returned.
 *
 * Note that ID values persist across frames, but only until tracking of a
 * particular object is lost. If tracking of a tool is lost and subsequently
 * regained, the new LeapTool object representing that tool may have a
 * different ID than that representing the tool in an earlier frame.
 *
 * @param toolId The ID value of a <LeapTool> object from a previous frame.
 * @returns The <LeapTool> object with the matching ID if one exists in this frame;
 * otherwise, an invalid LeapTool object is returned.
 */
- (LeapTool *)tool:(int32_t)toolId;
/**
 * The gestures recognized or continuing since the specified frame.
 *
 * Circle and swipe gestures are updated every frame. Tap gestures
 * only appear in the list for a single frame.
 *
 * @param sinceFrame An earlier LeapFrame. Set to nil to get the gestures for 
 * the current LeapFrame only.
 * @return NSArray containing the list of gestures.
 */
- (NSArray *)gestures:(const LeapFrame *)sinceFrame;
/**
 * The <LeapGesture> object with the specified ID in this frame.
 *
 * Use the [LeapFrame gesture:] function to return a Gesture object in this
 * frame using an ID obtained in an earlier frame. The function always
 * returns a LeapGesture object, but if there was no update for the gesture in
 * this frame, then an invalid LeapGesture object is returned.
 *
 * All LeapGesture objects representing the same recognized movement share the
 * same ID.
 * @param gestureId The ID of a <LeapGesture> object from a previous frame.
 * @returns The <LeapGesture> object in the frame with the specified ID if one
 * exists; Otherwise, an Invalid LeapGesture object.
 */
- (LeapGesture *)gesture:(int32_t)gestureId;
/**
 * The change of position derived from the overall linear motion between
 * the current frame and the specified frame.
 *
 * The returned translation vector provides the magnitude and direction of
 * the movement in millimeters.
 *
 * The Leap derives frame translation from the linear motion of
 * all objects detected in the field of view.
 *
 * If either this frame or sinceFrame is an invalid LeapFrame object, then this
 * method returns a zero vector.
 *
 * @param sinceFrame The starting frame for computing the relative translation.
 * @returns A <LeapVector> representing the heuristically determined change in
 * position of all objects between the current frame and that specified
 * in the sinceFrame parameter.
 */
- (LeapVector *)translation:(const LeapFrame *)sinceFrame;
/**
 * The axis of rotation derived from the overall rotational motion between
 * the current frame and the specified frame.
 *
 * The returned direction vector is normalized.
 *
 * The Leap derives frame rotation from the relative change in position and
 * orientation of all objects detected in the field of view.
 *
 * If either this frame or sinceFrame is an invalid LeapFrame object, or if no
 * rotation is detected between the two frames, a zero vector is returned.
 *
 * @param sinceFrame The starting frame for computing the relative rotation.
 * @returns A <LeapVector> containing the normalized direction vector representing the axis of the
 * heuristically determined rotational change between the current frame
 * and that specified in the sinceFrame parameter.
 */
- (LeapVector *)rotationAxis:(const LeapFrame *)sinceFrame;
/**
 * The angle of rotation around the rotation axis derived from the overall
 * rotational motion between the current frame and the specified frame.
 *
 * The returned angle is expressed in radians measured clockwise around the
 * rotation axis (using the right-hand rule) between the start and end frames.
 * The value is always between 0 and pi radians (0 and 180 degrees).
 *
 * The Leap derives frame rotation from the relative change in position and
 * orientation of all objects detected in the field of view.
 *
 * If either this frame or sinceFrame is an invalid LeapFrame object, then the
 * angle of rotation is zero.
 *
 * @param sinceFrame The starting frame for computing the relative rotation.
 * @returns A positive value containing the heuristically determined
 * rotational change between the current frame and that specified in the
 * sinceFrame parameter.
 */
- (float)rotationAngle:(const LeapFrame *)sinceFrame;
/**
 * The angle of rotation around the specified axis derived from the overall
 * rotational motion between the current frame and the specified frame.
 *
 * The returned angle is expressed in radians measured clockwise around the
 * rotation axis (using the right-hand rule) between the start and end frames.
 * The value is always between -pi and pi radians (-180 and 180 degrees).
 *
 * The Leap derives frame rotation from the relative change in position and
 * orientation of all objects detected in the field of view.
 *
 * If either this frame or sinceFrame is an invalid LeapFrame object, then the
 * angle of rotation is zero.
 *
 * @param sinceFrame The starting frame for computing the relative rotation.
 * @param axis The <LeapVector> representing the direction of the axis to measure rotation around.
 * @returns A value containing the heuristically determined rotational
 * change between the current frame and that specified in the sinceFrame
 * parameter around the given axis.
 */
- (float)rotationAngle:(const LeapFrame *)sinceFrame axis:(const LeapVector *)axis;
/**
 * The transform matrix expressing the rotation derived from the overall
 * rotational motion between the current frame and the specified frame.
 *
 * The Leap derives frame rotation from the relative change in position and
 * orientation of all objects detected in the field of view.
 *
 * If either this frame or sinceFrame is an invalid LeapFrame object, then this
 * method returns an identity matrix.
 *
 * @param sinceFrame The starting frame for computing the relative rotation.
 * @returns A <LeapMatrix> containing the heuristically determined
 * rotational change between the current frame and that specified in the
 * sinceFrame parameter.
 */
- (LeapMatrix *)rotationMatrix:(const LeapFrame *)sinceFrame;
/**
 * The scale factor derived from the overall motion between the current frame
 * and the specified frame.
 *
 * The scale factor is always positive. A value of 1.0 indicates no
 * scaling took place. Values between 0.0 and 1.0 indicate contraction
 * and values greater than 1.0 indicate expansion.
 *
 * The Leap derives scaling from the relative inward or outward motion of
 * all objects detected in the field of view (independent of translation
 * and rotation).
 *
 * If either this frame or sinceFrame is an invalid LeapFrame object, then this
 * method returns 1.0.
 *
 * @param sinceFrame The starting frame for computing the relative scaling.
 * @returns A positive value representing the heuristically determined
 * scaling change ratio between the current frame and that specified in the
 * sinceFrame parameter.
 */
- (float)scaleFactor:(const LeapFrame *)sinceFrame;
/**
 * Reports whether this LeapFrame instance is valid.
 *
 * A valid LeapFrame is one generated by the <LeapController> object that contains
 * tracking data for all detected entities. An invalid LeapFrame contains no
 * actual tracking data, but you can call its functions without risk of a
 * null pointer exception. The invalid LeapFrame mechanism makes it more
 * convenient to track individual data across the frame history. For example,
 * you can invoke:
 *
 *     `LeapFinger finger = [[controller frame:n] finger:fingerID];`
 *
 * for an arbitrary LeapFrame history value, "n", without first checking whether
 * frame: returned a null object. (You should still check that the
 * returned LeapFinger instance is valid.)
 *
 * @returns YES, if this is a valid LeapFrame object; false otherwise.
 */
- (BOOL)isValid;
@property (nonatomic, getter = isValid, readonly)BOOL isValid;
/**
 * Returns an invalid LeapFrame object.
 *
 * You can use the instance returned by this function in comparisons testing
 * whether a given LeapFrame instance is valid or invalid. (You can also use the
 * <[LeapFrame isValid]> function.)
 *
 * @returns The invalid LeapFrame instance.
 */
+ (LeapFrame *)invalid;

@end

//////////////////////////////////////////////////////////////////////////
//CONFIG
typedef enum {
    TYPE_UNKNOWN,
    TYPE_BOOLEAN,
    TYPE_INT32, TYPE_UINT32, TYPE_INT64, TYPE_UINT64,
    TYPE_FLOAT, TYPE_DOUBLE,
    TYPE_STRING
} LeapValueType;

@interface LeapConfig : NSObject

- (LeapValueType)type:(NSString *)key;
- (BOOL)getBool:(NSString *)key;
- (int32_t)getInt32:(NSString *)key;
- (int64_t)getInt64:(NSString *)key;
- (uint32_t)getUInt32:(NSString *)key;
- (uint64_t)getUInt64:(NSString *)key;
- (float)getFloat:(NSString *)key;
- (float)getDouble:(NSString *)key;
- (NSString *)getString:(NSString *)key;

@end

//////////////////////////////////////////////////////////////////////////
//CONTROLLER
/**
 * The LeapController class is your main interface to the Leap device.
 *
 * Create an instance of this LeapController class to access frames of tracking
 * data and configuration information. Frame data can be polled at any time
 * using the <[LeapController frame:]> function. Set the `frame:` parameter to 0 
 * to get the most recent frame. Set the parameter to a positive integer 
 * to access previous frames. For example, `[controller frame:10]` returns the
 * frame that occured ten frames ago. A controller stores up to 60 frames in its 
 * frame history.
 *
 * Polling is an appropriate strategy for applications which already have an
 * intrinsic update loop, such as a game. You can also add a listener object
 * or delegate to the controller to handle events as they occur.
 * The Leap dispatches events to the listener upon initialization and exiting,
 * on connection changes, and when a new frame of tracking data is available.
 * When these events occur, the controller object invokes the appropriate
 * callback function.
 *
 * **Polling**
 *
 * Create an instance of the LeapController class using the default initializer:
 *
 *     `LeapController *controller = [[LeapController alloc] init];`
 *
 * Access the frame data at regular intervals:
 *
 *     `LeapFrame *frame = [controller frame:0];`
 *
 * You can check <[LeapController isConnected]> to determine if the controller
 * is connected to the Leap software.
 *
 * **LeapListener protocol**
 *
 * Implement a class adopting the <LeapListener> protocol.
 *
 * Create an instance of the LeapController class and assign your LeapListener object to it:
 *
 *     `MYListener *listener = [[MYListener alloc] init];`
 *     `LeapController *controller = [[LeapController alloc] initWithListener:listener];`
 *
 * The controller subscribes the LeapListener instance to the appropriate NSNotifications
 * for the Leap events. When a new frame of data is ready, the controller dispatches an
 * NSNotification on the main application thread, which is handled by your
 * <[LeapListener onFrame:]> implementation.
 *
 * **LeapDelegate protocol**
 *
 * Implement a class adopting the <LeapDelegate> protocol.
 *
 * Create an instance of the LeapController class and assign your LeapListener object to it:
 *
 *     `MYDelegate *delegate = [[MYDelegate alloc] init];`
 *     `LeapController *controller = [[LeapController alloc] init];`
 *     `[controller addDelegate:delegate];`
 *
 * When a new frame of data is ready, the controller calls the
 * <[LeapDelegate onFrame:]> method. The Controller object is multithreaded and 
 * calls the LeapDelegate functions on its own thread, not on an application thread.
 *
 * You can handle the other Leap events, `onInit`, `onConnect`, `onDisconnect`,
 * and `onExit` in the same manner.
 */
@interface LeapController : NSObject

/**
 * Initializes a LeapController instance.
 */
- (id)init;
/**
 * Initializes a LeapController instance and assigns a listener.
 *
 * * *Note:* You can use either a listener or a delegate, but not both.
 *
 * @param listener An object adopting the <LeapListener> protocol.
 */
- (id)initWithListener:(id)listener;
/**
 * Adds a listener to this LeapController.
 *
 * When you add an object adopting the <LeapListener> protocol to a LeapController,
 * the controller automatically subscribes the listener to NSNotifications
 * dispatched for the Leap events.
 *
 * *Note:* You cannot add a listener when there is already a delegate assigned.
 *
 * @param listener An object adopting the <LeapListener> protocol. 
 * @returns BOOL Whether or not the listener was successfully added to the list
 * of listeners.
 */
- (BOOL)addListener:(id)listener;
/**
 * Unsubscribes the listener object from receiving Leap NSNotifications. 
 *
 * @param listener The listener to unsubscribe.
 * @returns BOOL Whether or not the listener was successfully removed.
 */
- (BOOL)removeListener:(id)listener;
/**
 * Initializes a LeapController instance and assigns a delegate.
 *
 * * *Note:* You can use either a delegate or a listener, but not both.
 *
 * @param delegate An object adopting the <LeapDelegate> protocol.
 */
- (id)initWithDelegate:(id)delegate;
/**
 * Adds a delegate to this LeapController.
 *
 * *Note:* You cannot add a delegate when there is already a listener assigned.
 *
 * @param delegate An object adopting the <LeapDelegate> protocol.
 * @returns BOOL Whether or not the delegate was successfully added.
 */
- (BOOL)addDelegate:(id)delegate;
/**
 * Removes the delegate assigned to this LeapController.
 *
 * @returns BOOL Whether or not the delegate was successfully removed.
 */
- (BOOL)removeDelegate;
/**
 * Returns a <LeapFrame> containing a frame of tracking data from the Leap. Use the optional
 * history parameter to specify which frame to retrieve. Call 
 * `[controller frame:0]` to access the most recent frame; call 
 * `[controller frame:1]` to access the previous frame, and so on. If you use a
 * history value greater than the number of stored frames, then the controller 
 * returns an invalid frame.
 *
 * @param history The age of the <LeapFrame> to return, counting backwards from
 * the most recent frame (0) into the past and up to the maximum age (59).
 * @returns The specified <LeapFrame>; or, if no history parameter is specified,
 * the newest frame. If a frame is not available at the specified history
 * position, an invalid LeapFrame is returned.
 */
- (LeapFrame *)frame:(int)history;
- (LeapConfig *)config;
@property (nonatomic, getter = config, readonly)LeapConfig *config;
/**
 * Reports whether this LeapController is connected to the Leap device.
 *
 * When you first create a LeapController object, isConnected returns false.
 * After the controller finishes initializing and connects to the Leap,
 * isConnected will return true.
 *
 * You can either handle the onConnect event using a <LeapListener> or <LeapDelegate> 
 * instance or poll the isConnected function if you need to wait for your
 * application to be connected to the Leap before performing some other
 * operation.
 *
 * @returns True, if connected; false otherwise.
 */
- (BOOL)isConnected;
@property (nonatomic, getter = isConnected, readonly)BOOL isConnected;
/**
 * Enables or disables reporting of a specified gesture type.
 *
 * By default, all gesture types are disabled. When disabled, gestures of the
 * disabled type are never reported and will not appear in the frame
 * gesture list.
 *
 * As a performance optimization, only enable recognition for the types
 * of movements that you use in your application.
 *
 * @param gestureType The type of gesture to enable or disable. Must be a
 * member of the LeapGestureType enumeration:
 *
 * * LEAP_GESTURE_TYPE_SWIPE  -- A straight line movement by the hand with fingers extended.
 * * LEAP_GESTURE_TYPE_CIRCLE -- A circular movement by a finger.
 * * LEAP_GESTURE_TYPE_SCREEN_TAP -- A forward tapping movement by a finger.
 * * LEAP_GESTURE_TYPE_KEY_TAP -- A downward tapping movement by a finger.
 *
 * @param enable YES, to enable the specified gesture type; NO,
 * to disable.
 * @see [LeapController isGestureEnabled:]
 */
- (void)enableGesture:(LeapGestureType)gestureType enable:(BOOL)enable;
/**
 * Reports whether the specified gesture type is enabled.
 *
 * @param gestureType The type of gesture to check.  Must be a
 * member of the LeapGestureType enumeration:
 *
 * * LEAP_GESTURE_TYPE_SWIPE  -- A straight line movement by the hand with fingers extended.
 * * LEAP_GESTURE_TYPE_CIRCLE -- A circular movement by a finger.
 * * LEAP_GESTURE_TYPE_SCREEN_TAP -- A forward tapping movement by a finger.
 * * LEAP_GESTURE_TYPE_KEY_TAP -- A downward tapping movement by a finger.
 *
 * @return YES, if the specified type is enabled; NO, otherwise.
 * @see [LeapController enableGesture:enable:]
 */
- (BOOL)isGestureEnabled:(LeapGestureType)gestureType;
/**
 * The list of <LeapScreen> objects representing the computer dieplay screens 
 * whose positions have been identified by using the Leap application 
 * Screen Locator utility.
 *
 * The list always contains at least one entry representing the default
 * screen. If the user has not registered the location of this default
 * screen, then the coordinates, directions, and other values reported by
 * the functions in its <LeapScreen> object will not be accurate. Other monitor
 * screens only appear in the list if their positions have been registered
 * using the Leap Screen Locator.
 *
 * A LeapScreen object represents the position and orientation of a display
 * monitor screen within the Leap coordinate system.
 * For example, if the screen location is known, you can get Leap coordinates
 * for the bottom-left corner of the screen. Registering the screen
 * location also allows the Leap to calculate the point on the screen at
 * which a finger or tool is pointing.
 *
 * A user can run the Screen Locator tool from the Leap application
 * Settings window. Avoid assuming that a screen location is known or that
 * an existing position is still correct. The registered position is only
 * valid as long as the relative position of the Leap device and the
 * monitor screen remain constant.
 *
 * @returns NSArray An array containing the screens whose positions have
 * been registered by the user using the Screen Locator tool.
 * The list always contains at least one entry representing the default
 * monitor. If the user has not run the Screen Locator or has moved the Leap
 * device or screen since running it, the <LeapScreen> object for this entry
 * only contains default values.
 */
- (NSArray *)calibratedScreens;
@property (nonatomic, getter = calibratedScreens, readonly)NSArray *calibratedScreens;

@end

//////////////////////////////////////////////////////////////////////////
//LISTENER
/**
 * The LeapListener protocol defines a set of methods that you can
 * implement to respond to NSNotification messages dispatched by a LeapController object.
 *
 * To use the LeapListener protocol, implement a class adopting the protocol
 * and assign an instance of that class to a <LeapController> instance:
 *
 *     `MYListener *listener = [[MYListener alloc] init];`
 *     `LeapController *controller = [[LeapController alloc] initWithListener:listener];`
 *
 * The controller subscribes the LeapListener instance to the appropriate NSNotifications
 * for the Leap events. When a new frame of data is ready, the controller dispatches an
 * NSNotification on the main application thread, which is handled by your
 * <[LeapListener onFrame:]> implementation.
 *
 * You can handle the other Leap events, `onInit`, `onConnect`, `onDisconnect`,
 * and `onExit` in the same manner.
 *
 * You must have a running NSRunLoop to receive NSNotification objects.
 * This is usually present and running by default in a Cocoa application.
 * Calling <[LeapController addListener:]> takes care subscribing the listener object
 * to the appropriate notifications. The LeapListener object is the notification observer,
 * while the LeapController object is the notification sender. You can also subscribe to
 * notifications manually. For example, to subscribe to the OnFrame message, call:
 *
 *     `[[NSNotificationCenter defaultCenter] selector:@selector(onFrame:) name:@"OnFrame" object:controller]]`
 *
 * However, at least one listener must be added to the controller with [LeapController addListener:]
 * or the controller does not bother to dispatch notification messages.
 *
 * Using the LeapListener protocol is not mandatory. You can also use
 * a delegate implementing the <LeapDelegate> protocol or simply poll the
 * controller object (as described in the <LeapController> class overview).
 */
@protocol LeapListener<NSObject>

@optional
/**
 * Dispatched once, when the <LeapController> has finished initializing.
 *
 * Only the first LeapListener added to the controller receives this notification.
 *
 *    `- (void)onInit:(NSNotification *)notification`
 *    `{
 *    `    NSLog(@"Initialized");`
 *    `    //...`
 *    `}`
 *
 * @param notification The <LeapController> object dispatching the notification.
 */
- (void)onInit:(NSNotification *)notification;
/**
 * Dispatched when the <LeapController> object connects to the Leap software, or when
 * this ListenerListener object is added to a controller that is already connected.
 *
 *     `- (void)onConnect:(NSNotification *)notification`
 *     `{`
 *     `   NSLog(@"Connected");`
 *     `    LeapController *aController = (LeapController *)[notification object];`
 *     `    [aController enableGesture:LEAP_GESTURE_TYPE_CIRCLE enable:YES];`
 *     `    //...`
 *     `}`
 *
 * @param notification The <LeapController> object dispatching the notification.
 */
- (void)onConnect:(NSNotification *)notification;
/**
 * Dispatched when the <LeapController> object disconnects from the Leap software.
 * The controller can disconnect when the Leap device is unplugged, the
 * user shuts the Leap software down, or the Leap software encounters an
 * unrecoverable error.
 *
 *     `- (void)onDisconnect:(NSNotification *)notification`
 *     `{`
 *     `    NSLog(@"Disconnected");`
 *     `}`
 *
 * Note: When you launch a Leap-enabled application in a debugger, the
 * Leap library does not disconnect from the application. This is to allow
 * you to step through code without losing the connection because of time outs.
 *
 * @param notification The <LeapController> object dispatching the notification.
 */
- (void)onDisconnect:(NSNotification *)notification;
/**
 * Dispatched when this LeapListener object is removed from the <LeapController>
 * or the controller instance is destroyed.
 *
 *     `- (void)onExit:(NSNotification *)notification`
 *     `{`
 *     `    NSLog(@"Exited");`
 *     `}`
 *
 * @param notification The <LeapController> object dispatching the notification.
 */
- (void)onExit:(NSNotification *)notification;
/**
 * Dispatched when a new <LeapFrame> containing hand and finger tracking data is available.
 * Access the new frame data using the <[LeapController frame:]> function.
 *
 *    `- (void)onFrame:(NSNotification *)notification`
 *    `{`
 *    `     NSLog(@"New LeapFrame");`
 *    `     LeapController *controller = (LeapController *)[notification object];`
 *    `     LeapFrame *frame = [controller frame:0];`
 *    `     //...`
 *    `}`
 *
 * Note, the <LeapController> skips any pending onFrame notifications while your
 * onFrame handler executes. If your implementation takes too long to return,
 * one or more frames can be skipped. The controller still inserts the skipped
 * frames into the frame history. You can access recent frames by setting
 * the history parameter when calling the [LeapController frame:] function.
 * You can determine if any pending onFrame events were skipped by comparing
 * the ID of the most recent frame with the ID of the last received frame.
 *
 * @param notification The <LeapController> object dispatching the notification.
 */
- (void)onFrame:(NSNotification *)notification;

@end

//////////////////////////////////////////////////////////////////////////
//DELEGATE
/**
 * The LeapDelegate protocol defines a set of methods that you can
 * implement in a delegate object for a <LeapController>. The
 * LeapController calls the delegate methods when Leap events occur,
 * such as when a new frame of data is available.
 *
 * To use the LeapDelegate protocol, implement a class adopting the <LeapDelegate> protocol
 * and assign it to a LeapController instance:
 *
 *     `MYDelegate *delegate = [[MYDelegate alloc] init];`
 *     `LeapController *controller = [[LeapController alloc] init];`
 *     `[controller addDelegate:delegate];`
 *
 * When a new frame of data is ready, the controller calls the
 * <[LeapDelegate onFrame:]> method. The other Leap events, `onInit`, `onConnect`, `onDisconnect`,
 * and `onExit` are handled in the same manner. The Controller object is multithreaded and calls the
 * LeapDelegate functions on its own threads, not on an application thread.
 *
 * Using the LeapDelegate protocol is not mandatory. You can also use
 * NSNotifications with a <LeapListener> object or simply poll the
 * controller object (as described in the <LeapController> class overview).
 */
@protocol LeapDelegate<NSObject>

@optional
/**
 * Called once, when the <LeapController> has finished initializing.
 *
 *
 *    `- (void)onInit:(LeapController *)controller`
 *    `{`
 *    `    NSLog(@"Initialized");`
 *    `    //...`
 *    `}`
 *
 * @param controller The parent <LeapController> object.
 */
- (void)onInit:(LeapController *)controller;
/**
 * Called when the <LeapController> object connects to the Leap software, or when
 * this ListenerDelegate object is added to a controller that is already connected.
 *
 *     `- (void)onConnect:(LeapController *)controller`
 *     `{`
 *     `    NSLog(@"Connected");`
 *     `    [controller enableGesture:LEAP_GESTURE_TYPE_CIRCLE enable:YES];`
 *     `    //...`
 *     `}`
 *
 * @param controller The parent <LeapController> object.
 */
- (void)onConnect:(LeapController *)controller;
/**
 * Called when the <LeapController> object disconnects from the Leap software.
 * The controller can disconnect when the Leap device is unplugged, the
 * user shuts the Leap software down, or the Leap software encounters an
 * unrecoverable error.
 *
 *     `- (void)onDisconnect:(LeapController *)controller`
 *     `{`
 *     `    NSLog(@"Disconnected");`
 *     `}`
 *
 * @param controller The parent <LeapController> object.
 */
- (void)onDisconnect:(LeapController *)controller;
/**
 * Called when this LeapDelegate object is removed from the <LeapController>
 * or the controller instance is destroyed.
 *
 *     `- (void)onExit:(LeapController *)controller`
 *     `{`
 *     `    NSLog(@"Exited");`
 *     `}`
 *
 * Note: When you launch a Leap-enabled application in a debugger, the 
 * Leap library does not disconnect from the application. This is to allow
 * you to step through code without losing the connection because of time outs.
 *
 * @param controller The parent <LeapController> object.
 */
- (void)onExit:(LeapController *)controller;
/**
 * Called when a new frame of hand and finger tracking data is available.
 * Access the new frame data using the <[LeapController frame:]> function.
 *
 *    `- (void)onFrame:(LeapController *)controller`
 *    `{`
 *    `     NSLog(@"New LeapFrame");`
 *    `     LeapFrame *frame = [controller frame:0];`
 *    `     //...`
 *    `}`
 *
 * Note, the LeapController skips any pending frames while your
 * onFrame handler executes. If your implementation takes too long to return,
 * one or more frames can be skipped. The controller still inserts the skipped
 * frames into the frame history. You can access recent frames by setting
 * the history parameter when calling the <[LeapController frame:]> function.
 * You can determine if any pending frames were skipped by comparing
 * the ID of the current frame with the ID of the previous received frame.
 *
 * @param controller The parent <LeapController> object.
 */
- (void)onFrame:(LeapController *)controller;

@end



//////////////////////////////////////////////////////////////////////////
