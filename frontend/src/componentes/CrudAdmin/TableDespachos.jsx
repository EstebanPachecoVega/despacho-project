import { useState, useEffect } from "react";
import axios from "axios";
import { Modal } from "./Modal";
import { FormCierreDespacho } from "./FormCierreDespacho";
import Swal from "sweetalert2";

export const TableDespachos = ({ searchTerm = "" }) => {
  const [despachos, setDespachos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const despacho = async () => {
    setLoading(true);
    await axios
      .get("/api/v1/despachos", {
        headers:{
              'Content-Type': 'application/json',
              'Accept': 'application/json'
        }
      })
      .then((response) => {
        console.log(response.data);
        setDespachos(response.data);
        setError(null);
      })
      .catch((error) => {
        console.error("Error al cargar despachos:", error);
        setError("No se pudieron cargar las ordenes de despacho. Verifica que los servicios backend esten funcionando.");
        Swal.fire({
          title: "Error de conexion",
          text: error.response?.data?.message || "No se pudo conectar con el servicio de despachos. Asegurate de que el backend este corriendo.",
          icon: "error",
          confirmButtonText: "Aceptar",
        });
      })
      .finally(() => {
        setLoading(false);
      });
  };
  // Llamada a la función para obtener los datos cuando el componente se monta
  useEffect(() => {
    despacho();
  }, []);

  const [openModal, setOpenModal] = useState(false);
  const [despachoSeleccionado, setDespachoSeleccionado] = useState(null);

  const handleAbrirModal = (despacho) => {
    setDespachoSeleccionado(despacho);
    setOpenModal(true);
  };

  return (
    <>
      <section className="grid text-center grid-cols-12 mb-8">
        <div className="col-span-12 flex justify-center">
          <div className="col-span-10 p-2 bg-white border border-gray-200 rounded-lg shadow dark:bg-white h-full overflow-hidden">
            <table className="table-fixed">
              <thead>
                <tr className="py-10">
                  <th className="pr-10">Orden de despacho</th>
                  <th className="pr-10">Orden de compra</th>
                  <th className="pr-10">Dirección de entrega</th>
                  <th className="pr-10">Fecha despacho</th>
                  <th className="pr-10">Patente Camión</th>
                  <th className="pr-10">Entregado</th>
                  <th className="pr-10">Intentos de entrega</th>
                </tr>
              </thead>
              <tbody>
                {loading && (
                  <tr>
                    <td colSpan={8} className="py-10 text-center text-gray-500">
                      Cargando ordenes de despacho...
                    </td>
                  </tr>
                )}
                {error && !loading && (
                  <tr>
                    <td colSpan={8} className="py-10 text-center text-red-500">
                      {error}
                    </td>
                  </tr>
                )}
                {!loading && !error && despachos.length === 0 && (
                  <tr>
                    <td colSpan={8} className="py-10 text-center text-gray-500">
                      No hay ordenes de despacho registradas.
                    </td>
                  </tr>
                )}
                {!loading && !error && despachos
                .filter((despacho) =>
                  !searchTerm ||
                  String(despacho.idDespacho).includes(searchTerm) ||
                  String(despacho.idCompra).includes(searchTerm) ||
                  (despacho.direccionCompra && despacho.direccionCompra.toLowerCase().includes(searchTerm.toLowerCase())) ||
                  (despacho.patenteCamion && despacho.patenteCamion.toLowerCase().includes(searchTerm.toLowerCase()))
                )
                .map((despacho) => (
                  <tr key={despacho.idDespacho}>
                    <td className="pr-10 py-10 items-center">{despacho.idDespacho}</td>
                    <td className="pr-10 py-10  items-center">
                      {despacho.idCompra}
                    </td>
                    <td className="pr-10 py-10  items-center">
                      {despacho.direccionCompra}
                    </td>
                    <td className="pr-10 py-10  items-center">
                      {despacho.fechaDespacho}
                    </td>
                    <td className="pr-10 py-10  items-center">
                      {despacho.patenteCamion}
                    </td>
                    <td className="pr-10 py-10  items-center">
                      {despacho.despachado
                        ? "Despacho entregado"
                        : "Despacho pendiente"}
                    </td>
                    <td className="pr-10 py-10  items-center">
                      {despacho.intento}
                    </td>
                    <td>
                      <button
                        onClick={() => handleAbrirModal(despacho)}
                        className="py-1 bg-orange-200 px-8 rounded-xl shadow-md hover:bg-orange-300/70 transition-all duration-300 "
                      >
                        Cerrar despacho
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>
      <Modal
        onClose={() => {
          setOpenModal(false);
        }}
        open={openModal}
      >
        {despachoSeleccionado && (
          <FormCierreDespacho
            despacho={despachoSeleccionado}
            onClose={() => {
              //onclose es un prop que pasa funciones al modal con el form abierto, por ende al cerrarse, se ejecutan esas 2 funciones
              setOpenModal(false), despacho();
            }}
          />
        )}
      </Modal>
    </>
  );
};
