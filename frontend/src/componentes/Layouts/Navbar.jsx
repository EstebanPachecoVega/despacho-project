import { Link } from "react-router-dom";

function Navbar() {
  return (
    <nav className="rounded-xl w-[250px] min-h-[880px] bg-teal-600 text-white sticky top-0 p-4 m-4">
      <h2 className="text-xl font-bold mb-8">Despacho Dashboard</h2>

      <ul className="space-y-3">
        <li>
          <Link
            to="/"
            className="block font-bold py-2 px-3 hover:bg-teal-700 rounded"
          >
            Dashboard
          </Link>
        </li>
        <li>
          <Link
            to="/usuarios"
            className="block font-bold py-2 px-3 hover:bg-teal-700 rounded"
          >
            Usuarios
          </Link>
        </li>
        <li>
          <Link
            to="/productos"
            className="block font-bold py-2 px-3 hover:bg-teal-700 rounded"
          >
            Productos
          </Link>
        </li>
        <li>
          <Link
            to="/configuracion"
            className="block font-bold py-2 px-3 hover:bg-teal-700 rounded"
          >
            Configuración
          </Link>
        </li>
      </ul>
    </nav>
  );
}

export default Navbar;
