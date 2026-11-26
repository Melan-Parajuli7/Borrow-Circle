// BorrowCircle theme — same palette as the Flutter app, exposed in JS for
// components that need values (e.g. status colors) instead of CSS classes.
export const theme = {
  colors: {
    primary: "#0F766E",
    primaryHover: "#0E6A63",
    primaryLight: "#E7F1F1",
    primaryLightActive: "#B5D5D2",
    secondary: "#10B981",
    secondaryLight: "#E7F8F2",
    tertiary: "#F59E0B",
    tertiaryLight: "#FEF5E7",
    tertiaryDark: "#B87708",
    background: "#FFFFFF",
    surface: "#EFF4F3",
    border: "#E2EAE8",
    textDark: "#052927",
    textGrey: "#5F7370",
    error: "#DC2626",
    errorLight: "#FDECEC",
    success: "#10B981",
    successLight: "#E7F8F2",
    warning: "#F59E0B",
    warningLight: "#FEF5E7",
  },
  spacing: {
    xs: "4px",
    sm: "8px",
    md: "16px",
    lg: "24px",
    xl: "32px",
    xxl: "48px",
  },
  borderRadius: {
    sm: "6px",
    md: "10px",
    lg: "16px",
    xl: "24px",
    full: "9999px",
  },
  breakpoints: {
    sm: "640px",
    md: "768px",
    lg: "1024px",
    xl: "1280px",
    "2xl": "1536px",
  },
};

export default theme;