import type { Metadata } from "next";
import { Geist_Mono } from "next/font/google";
import { ThemeProvider } from "./components/ThemeProvider";
import "./globals.css";

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "TUIkit — Terminal UI Framework for Swift",
  description:
    "A declarative, SwiftUI-like framework for building Terminal User Interfaces in Swift. No ncurses, no C dependencies — pure Swift.",
  openGraph: {
    title: "TUIkit — Terminal UI Framework for Swift",
    description:
      "Build terminal apps with SwiftUI-like syntax. Pure Swift, no ncurses.",
    url: "https://tuikit.layered.work",
    siteName: "TUIkit",
    type: "website",
  },
  icons: {
    icon: "/tuikit-logo.png",
    apple: "/tuikit-logo.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  /** Inline script that runs before first paint to prevent theme flash (FOUC). */
  const themeInitScript = `
    (function() {
      try {
        var stored = localStorage.getItem('tuikit-theme');
        if (stored && ['green','amber','white','red'].includes(stored)) {
          document.documentElement.setAttribute('data-theme', stored);
        } else {
          document.documentElement.setAttribute('data-theme', 'amber');
        }
      } catch(e) {
        document.documentElement.setAttribute('data-theme', 'amber');
      }
    })();
  `;

  return (
    <html lang="en" className="dark" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeInitScript }} />
      </head>
      <body
        className={`${geistMono.variable} antialiased`}
      >
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
