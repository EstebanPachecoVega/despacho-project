import { useState } from "react";
import { CardComponent } from "./CardComponent";
import { TableCompras } from "./TableCompras";
import { TableDespachos } from "./TableDespachos";
import { SearchBar } from "./SearchBar";

export const PruebaCards = () => {
  const [tablaCompras, setTablaCompras] = useState(false);
  const [tablaOrdenes, setTablaOrdenes] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");

  return (
    <section>
      <div className="flex justify-center">
        <CardComponent
          title="Consultar Ordenes de compra 💰"
          description="Revisa las últimas oc realizadas para generar su despacho"
          buttonText="Consultar"
          onClick={() => {
            setTablaCompras(true);
            setTablaOrdenes(false);
          }}
        />
        <CardComponent
          title="Revisar Ordenes de despacho 🚚"
          description="Consulta los despachos realizados, modifica los registros de intentos o cierra la orden"
          buttonText="Consultar"
          onClick={() => {
            setTablaCompras(false);
            setTablaOrdenes(true);
          }}
        />
      </div>

      <SearchBar searchTerm={searchTerm} onSearch={setSearchTerm} />

      <section>
        {tablaCompras && <TableCompras searchTerm={searchTerm} />}
        {tablaOrdenes && <TableDespachos searchTerm={searchTerm} />}
      </section>
    </section>
  );
};
