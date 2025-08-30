import React, { useState, useEffect } from 'react';
import { Table, Pagination, Spin, message } from 'antd';
import { dryrun } from '@permaweb/aoconnect';
import dayjs from 'dayjs';

interface Task {
  twit: {
    txt: string;
    username: string;
  };
  status: string;
  response: {
    score: number | null;
    reasoning: string;
  };
  starttime: number;
  endtime?: number;
}

interface TasksResponse {
  start: number;
  limit: number;
  total: number;
  count: number;
  has_more: boolean;
  tasks: Record<string, Task>;
}

const TasksTable: React.FC = () => {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [total, setTotal] = useState(0);

  const processId = "MMs2Ycxq46Pz3mC2bhz--4XFbPQjiDvR-9g-qKaxg2s";

  const fetchTasks = async (page: number, size: number) => {
    setLoading(true);
    try {
      const start = (page - 1) * size + 1;
      const response = await dryrun({
        process: processId,
        tags: [
          { name: "Action", value: "GetTasks" },
          { name: "start", value: start.toString() },
          { name: "limit", value: size.toString() }
        ]
      });

      // Extract data from dryrun response
      const raw = response?.Messages?.[0]?.Data;
      if (raw) {
        const data: TasksResponse = JSON.parse(raw);
        setTasks(Object.values(data.tasks));
        setTotal(data.total);
        setCurrentPage(page);
      }
    } catch (error) {
      console.error('Error fetching tasks:', error);
      message.error('Failed to fetch tasks');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTasks(currentPage, pageSize);
  }, []);

  const handlePageChange = (page: number, size?: number) => {
    const newPageSize = size || pageSize;
    setPageSize(newPageSize);
    fetchTasks(page, newPageSize);
  };

  const columns = [
    {
      title: 'Tweet Text',
      dataIndex: 'twit',
      key: 'twit',
      render: (twit: any) => (
        <div style={{ maxWidth: 300, wordBreak: 'break-word' }}>
          {twit.txt}
        </div>
      ),
    },
    {
      title: 'Username',
      dataIndex: ['twit', 'username'],
      key: 'username',
      width: 120,
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      width: 100,
      render: (status: string) => (
        <span style={{
          padding: '4px 8px',
          borderRadius: '4px',
          fontSize: '12px',
          fontWeight: 'bold',
          backgroundColor: status === 'success' ? '#52c41a' : status === 'processing' ? '#1890ff' : '#ff4d4f',
          color: 'white'
        }}>
          {status}
        </span>
      ),
    },
    {
      title: 'Score',
      dataIndex: ['response', 'score'],
      key: 'score',
      width: 80,
      render: (score: number | null) => score || '-',
    },
    {
      title: 'Reasoning',
      dataIndex: ['response', 'reasoning'],
      key: 'reasoning',
      render: (reasoning: string) => (
        <div style={{ maxWidth: 300, wordBreak: 'break-word' }}>
          {reasoning}
        </div>
      ),
    },
    {
      title: 'Start Time',
      dataIndex: 'starttime',
      key: 'starttime',
      width: 150,
      render: (timestamp: number) => {
        // Handle both seconds and milliseconds
        const date = timestamp > 1000000000000 ? new Date(timestamp) : new Date(timestamp * 1000);
        return dayjs(date).format('YYYY-MM-DD HH:mm:ss');
      },
    },
    {
      title: 'End Time',
      dataIndex: 'endtime',
      key: 'endtime',
      width: 150,
      render: (timestamp?: number) => {
        if (!timestamp) return '-';
        // Handle both seconds and milliseconds
        const date = timestamp > 1000000000000 ? new Date(timestamp) : new Date(timestamp * 1000);
        return dayjs(date).format('YYYY-MM-DD HH:mm:ss');
      },
    },
  ];

  return (
    <div style={{ padding: '20px' }}>
      <h2 style={{ marginBottom: '20px', color: '#333' }}>Twitter IQ Analysis Results</h2>
      
      <Spin spinning={loading}>
        <Table
          columns={columns}
          dataSource={tasks}
          rowKey={(record, index) => index?.toString() || '0'}
          pagination={false}
          scroll={{ x: 1200 }}
          size="small"
        />
      </Spin>

      <div style={{ marginTop: '20px', textAlign: 'center' }}>
        <Pagination
          current={currentPage}
          pageSize={pageSize}
          total={total}
          showSizeChanger
          showQuickJumper
          showTotal={(total, range) => `${range[0]}-${range[1]} of ${total} items`}
          onChange={handlePageChange}
          onShowSizeChange={handlePageChange}
        />
      </div>
    </div>
  );
};

export default TasksTable;
