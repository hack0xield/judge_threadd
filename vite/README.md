# Twitter IQ Measurement Dashboard

A React dashboard to display Twitter IQ analysis results from your AO process with pagination.

## Features

- **IQ Analysis Table**: Displays all Twitter IQ analysis results from your AO process
- **Pagination**: Navigate through results with configurable page sizes
- **Real-time Data**: Fetches data directly from your AO process
- **Responsive Design**: Works on desktop and mobile devices

## Table Columns

- **Tweet Text**: The content of the tweet being analyzed
- **Username**: The Twitter username
- **Status**: Analysis status (processing, success, failed)
- **Score**: IQ score (60-140) from the AI analysis
- **Reasoning**: AI explanation for the score
- **Start Time**: When the analysis was created
- **End Time**: When the analysis completed

## Setup

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Start development server**:
   ```bash
   npm run dev
   ```

3. **Build for production**:
   ```bash
   npm run build
   ```

## Configuration

The dashboard is configured to connect to your AO process:
- **Process ID**: `MMs2Ycxq46Pz3mC2bhz--4XFbPQjiDvR-9g-qKaxg2s`
- **Handler**: `GetTasks` with pagination support

## Usage

The dashboard automatically loads the first page of IQ analysis results when it starts. You can:
- Change page size (10, 20, 50, 100 items per page)
- Navigate between pages
- See total analysis count and current page information

## Dependencies

- **React 18** - UI framework
- **TypeScript** - Type safety
- **Ant Design** - UI components
- **AO Connect** - AO network communication
- **Day.js** - Date formatting

## Project Structure

```
src/
├── components/
│   └── TasksTable.tsx    # Main table component
├── App.tsx               # Main app component
├── main.tsx             # Entry point
└── index.css            # Global styles
```

## AO Process Integration

The dashboard communicates with your AO process using the `GetTasks` handler:
- Sends pagination parameters (start, limit)
- Receives JSON response with analysis results and metadata
- Handles loading states and errors gracefully
