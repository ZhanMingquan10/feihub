import { useEffect } from "react";

const suspiciousKeys = ["PrintScreen", "F12"];

interface Options {
  onFlagged?: (reason: string) => void;
}

export function useAntiScrapeShield(options: Options = {}) {
    useEffect(() => {
        let copyCount = 0;
        const handler = (event: Event) => {
            if (event.type === "copy") {
                copyCount += 1;
                if (copyCount > 5) {
                    options?.onFlagged?.("copy-threshold");
                }
            }
            if (event.type === "contextmenu") {
                event.preventDefault();
            }
            if (event.type === "keydown") {
                const keyEvent = event as KeyboardEvent;
                if (keyEvent.ctrlKey && keyEvent.key.toLowerCase() === "s") {
                    event.preventDefault();
                }
                if (suspiciousKeys.includes(keyEvent.key)) {
                    options?.onFlagged?.("devtools-key");
                }
            }
        };
        document.addEventListener("copy", handler);
        document.addEventListener("contextmenu", handler);
        document.addEventListener("keydown", handler);
        return () => {
            document.removeEventListener("copy", handler);
            document.removeEventListener("contextmenu", handler);
            document.removeEventListener("keydown", handler);
        };
    }, [options]);
}
