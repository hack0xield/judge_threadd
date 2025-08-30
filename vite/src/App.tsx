import React from "react";
import TasksTable from "./components/TasksTable";

const App: React.FC = () => {
  return (
    <div style={{ 
      minHeight: "100vh", 
      background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
      position: "relative",
      overflow: "hidden"
    }}>
      {/* Background decoration */}
      <div style={{
        position: "absolute",
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        background: "radial-gradient(circle at 20% 80%, rgba(120, 119, 198, 0.3) 0%, transparent 50%), radial-gradient(circle at 80% 20%, rgba(255, 119, 198, 0.3) 0%, transparent 50%)",
        pointerEvents: "none"
      }} />
      
      <div style={{ 
        position: "relative", 
        zIndex: 1,
        padding: "40px 20px",
        maxWidth: 1400,
        margin: "0 auto"
      }}>
        <h1 style={{ 
          textAlign: "center", 
          color: "white", 
          fontSize: "2.5rem",
          fontWeight: 700,
          marginBottom: 60,
          textShadow: "0 2px 4px rgba(0,0,0,0.3)",
          letterSpacing: "0.5px"
        }}>
          Twitter IQ Measurement
        </h1>
        
        <div style={{ 
          backgroundColor: "white",
          borderRadius: "12px",
          boxShadow: "0 8px 32px rgba(0,0,0,0.1)",
          overflow: "hidden"
        }}>
          <TasksTable />
        </div>
      </div>
    </div>
  );
};

export default App; 