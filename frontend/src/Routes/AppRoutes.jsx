import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import { CrudAdmin } from "../componentes/CrudAdmin.jsx";
import Usuarios from "../pages/Usuarios.jsx";
import Productos from "../pages/Productos.jsx";
import Configuracion from "../pages/Configuracion.jsx";

const AppRoutes = () => {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<CrudAdmin />} />
        <Route path="/usuarios" element={<Usuarios />} />
        <Route path="/productos" element={<Productos />} />
        <Route path="/configuracion" element={<Configuracion />} />
      </Routes>
    </Router>
  );
};

export default AppRoutes;
