// The Lehwi Palance mark, redrawn from apps/customer/assets/logo1.jpeg.
//
// Kept: the map pin, the P monogram, the turquoise-magenta-purple spectrum.
// Dropped: the palm tree, the sunset and the road inside the pin, the chrome
// bevel, and the opaque white box the original JPEG was baked onto. The
// original had no vector and could not sit on anything but white.
//
// Geometry: the pin head is a circle of r22 at (24,24) closing to a point at
// (24,62); the P is built on the same centre so the monogram stays optically
// centred in the head at every size.

const PIN =
  "M24 62 C16 50 2 37 2 24 A22 22 0 1 1 46 24 C46 37 32 50 24 62 Z";
// Two subpaths: the letter, then its counter. fill-rule evenodd punches the
// bowl so the flat variant reads as one colour with a real hole in it.
const P_OUTER = "M14 11 H26 A7.5 7.5 0 0 1 26 26 H20 V37 H14 Z";
const P_COUNTER = "M20 16 H26 A2.5 2.5 0 0 1 26 21 H20 Z";

/** The pin. `flat` renders one-colour in currentColor for small sizes, dark
 *  surfaces and the favicon; otherwise the spectrum runs through the pin. */
export function Mark({ size = 28, flat = false }: { size?: number; flat?: boolean }) {
  if (flat) {
    return (
      <svg viewBox="0 0 48 64" width={(size * 48) / 64} height={size} aria-hidden="true" focusable="false">
        <path d={`${PIN} ${P_OUTER} ${P_COUNTER}`} fill="currentColor" fillRule="evenodd" />
      </svg>
    );
  }
  return (
    <svg viewBox="0 0 48 64" width={(size * 48) / 64} height={size} aria-hidden="true" focusable="false">
      <defs>
        <linearGradient id="lp-pin" x1="10" y1="3" x2="38" y2="61" gradientUnits="userSpaceOnUse">
          <stop offset="0" stopColor="#10E8E8" />
          <stop offset="0.45" stopColor="#3FA8E8" />
          <stop offset="0.76" stopColor="#B030F0" />
          <stop offset="1" stopColor="#F010B0" />
        </linearGradient>
      </defs>
      <path d={PIN} fill="url(#lp-pin)" />
      <path d={`${P_OUTER} ${P_COUNTER}`} fill="#FFFFFF" fillRule="evenodd" />
    </svg>
  );
}

/** Mark plus wordmark. The original set LEHWI and PALANCE in two colours of
 *  the spectrum; that is kept, as real text rather than baked pixels, so it
 *  stays crisp, selectable and translatable. */
export function Logo({ size = 24 }: { size?: number }) {
  return (
    <span className="logo">
      <Mark size={size + 8} />
      <span className="logo-word" style={{ fontSize: size }}>
        <span className="logo-lehwi">Lehwi</span>
        <span className="logo-palance">Palance</span>
      </span>
    </span>
  );
}
