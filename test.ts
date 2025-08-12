// Test TypeScript file with missing imports
interface User {
  name: string;
  age: number;
}

const user: User = {
  name: "Test",
  age: 25
};

// This should trigger import suggestions
const state = useState(0);
const effect = useEffect(() => {}, []);

// This should also need imports
const data = axios.get('/api/users');

function greet(user: User): string {
  return `Hello, ${user.name}!`;
}

console.log(greet(user));