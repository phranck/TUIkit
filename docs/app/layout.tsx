import type { Metadata } from "next";
import { Geist_Mono } from "next/font/google";
import { ThemeProvider } from "./components/ThemeProvider";
import "./globals.css";

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL("https://tuikit.layered.work"),
  alternates: {
    canonical: "/",
  },
  title: "TUIkit — Terminal UI Framework for Swift",
  description:
    "A declarative, SwiftUI-like framework for building Terminal User Interfaces in Swift. No ncurses, no C dependencies — pure Swift.",
  keywords: [
    "swift", "terminal", "TUI", "framework", "SwiftUI", "CLI",
    "ncurses alternative", "macOS", "Linux", "terminal UI", "declarative",
  ],
  openGraph: {
    title: "TUIkit — Terminal UI Framework for Swift",
    description:
      "Build terminal apps with SwiftUI-like syntax. Pure Swift, no ncurses.",
    url: "https://tuikit.layered.work",
    siteName: "TUIkit",
    type: "website",
    images: [
      {
        url: "/og-image.png",
        width: 1200,
        height: 630,
        alt: "TUIkit — Terminal UI Framework for Swift",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "TUIkit — Terminal UI Framework for Swift",
    description:
      "Build terminal apps with SwiftUI-like syntax. Pure Swift, no ncurses.",
    images: ["/og-image.png"],
  },
  icons: {
    icon: [
      { url: "/favicon-32.png", sizes: "32x32", type: "image/png" },
      { url: "/favicon-192.png", sizes: "192x192", type: "image/png" },
      { url: "/favicon-512.png", sizes: "512x512", type: "image/png" },
    ],
    apple: "/favicon-512.png",
  },
  manifest: "/site.webmanifest",
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
        if (stored && ['green','amber','red','violet','blue','white'].includes(stored)) {
          document.documentElement.setAttribute('data-theme', stored);
        } else {
          document.documentElement.setAttribute('data-theme', 'green');
        }
      } catch(e) {
        document.documentElement.setAttribute('data-theme', 'green');
      }
    })();
  `;

  return (
    <html lang="en" className="dark" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeInitScript }} />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              "@context": "https://schema.org",
              "@type": "SoftwareSourceCode",
              name: "TUIkit",
              description:
                "A declarative, SwiftUI-like framework for building Terminal User Interfaces in Swift.",
              url: "https://tuikit.layered.work",
              codeRepository: "https://github.com/phranck/TUIkit",
              programmingLanguage: "Swift",
              operatingSystem: ["macOS", "Linux"],
              license: "https://creativecommons.org/licenses/by-nc-sa/4.0/",
            }),
          }}
        />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link rel="preconnect" href="https://cloud.umami.is" />
        <script defer src="https://cloud.umami.is/script.js" data-website-id="4085eff5-2e56-4e3a-ba91-cf0828914169" />
      </head>
      <body
        className={`${geistMono.variable} antialiased`}
      >
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
