import { createRoot } from "react-dom/client";
import App from "./App";
import { ConfigProvider } from "antd";
import "./index.css";

console.log("main.tsx is loading...");

const root = document.getElementById("root");
console.log("Root element:", root);

if (root) {
  console.log("Creating React root...");
  const reactRoot = createRoot(root);
  
  reactRoot.render(
    <ConfigProvider>
      <App />
    </ConfigProvider>
  );
  
  console.log("React app rendered successfully");
} else {
  console.error("Root element not found!");
}
