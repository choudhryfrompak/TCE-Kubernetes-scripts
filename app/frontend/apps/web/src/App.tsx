import { useEffect, useState } from "react";
import reactLogo from "./assets/react.svg";
import viteLogo from "/vite.svg";
import "./App.css";

interface WeatherForecast {
  date: string;
  temperatureC: number;
  summary: string;
  temperatureF: number;
}

function App() {
  const [count, setCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState<WeatherForecast[]>([]);
  const apiUrl = import.meta.env.VITE_API_URL;

  useEffect(() => {
    const callApi = async () => {
      const response = await fetch(`${import.meta.env.VITE_API_URL}/weatherforecast`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const dataApi: WeatherForecast[] = await response.json();
      setData(dataApi);
      setLoading(false);
    };
    callApi();
  }, []);

  return (
    <>
      <div>
        <a href="https://vite.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <h1>Vite + React</h1>
      <div className="card">
        <button onClick={() => setCount((count) => count + 1)}>
          count is {count}
        </button>
        <p>
          Edit <code>src/App.tsx</code> and save to test HMR
        </p>
      </div>
      <p className="read-the-docs">
        Click on the Vite and React logos to learn more
      </p>
      <p>This value is from config: {apiUrl}</p>
      <p>Weather forcast from api</p>
      {loading ? (
        <p>Loading...</p>
      ) : (
        <ul>
          {data.map((d) => (
            <li key={d.date} >{d.summary}</li>
          ))}
        </ul>
      )}
    </>
  );
}

export default App;
