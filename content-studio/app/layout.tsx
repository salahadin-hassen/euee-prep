import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "EUEE Content Studio",
  description: "Internal authoring and review workspace for EUEE content.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
