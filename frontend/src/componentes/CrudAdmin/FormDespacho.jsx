import { useForm } from "react-hook-form";
import Swal from "sweetalert2";
import axios from "axios";

export const FormDespacho = ({ venta, onClose }) => {
  const { register, handleSubmit, formState: { errors } } = useForm();

  const today = new Date().toISOString().split("T")[0];

  const onSubmit = async (data) => {
    console.log("onSubmit ejecutado");
    const jsonData = {
      fechaDespacho: data.fechaDespacho,
      patenteCamion: data.patenteCamion,
      intento: 0,
      despachado: false,
      idCompra: venta.idVenta,
      direccionCompra: venta.direccionCompra,
      valorCompra: venta.valorCompra,
    };

    const jsonDataSales = {
      despachoGenerado: true,
    };

    console.log("Datos del formulario:", jsonData);

    try {
      await axios.post("/api/v1/despachos", jsonData, {
        headers:{
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }
      });
      await axios.put(
        `/api/v1/ventas/${venta.idVenta}`,
        jsonDataSales,
        {
          headers:{
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          }
        }
      );
      Swal.fire({
        title: "¡Despacho registrado!",
        text: `El despacho para la orden #${venta.idVenta} (${venta.direccionCompra}) ha sido generado exitosamente.`,
        icon: "success",
        confirmButtonText: "Aceptar",
      });
      onClose();
    } catch (error) {
      console.error("Error en la solicitud:", error);
      const serverMsg = error.response?.data?.message;
      const fieldErrors = error.response?.data?.errors;
      let errorText = serverMsg || "Ocurrió un error al registrar el despacho.";

      if (fieldErrors && Object.keys(fieldErrors).length > 0) {
        errorText += "\n\n" + Object.entries(fieldErrors)
          .map(([campo, mensaje]) => `• ${campo}: ${mensaje}`)
          .join("\n");
      }

      Swal.fire({
        title: "Error al generar despacho",
        text: errorText,
        icon: "error",
        confirmButtonText: "Aceptar",
      });
    }
  };
  return (
    <>
      <form
        onSubmit={handleSubmit(onSubmit)}
        className="flex flex-col justify-center text-center px-24 text-xl"
      >
        <div className="mx-auto text-3xl font-bold mb-10 text-teal-600">
          Ingreso de orden de despacho
        </div>
        <div className="mb-5">
          <label className="block font-bold mb-2">Fecha de despacho</label>
          <input
            type="date"
            min={today}
            placeholder="Ingresa fecha de despacho"
            className={`border rounded-lg block w-full p-1 ${errors.fechaDespacho ? "border-red-500" : "border-gray-300"}`}
            {...register("fechaDespacho", {
              required: "Debes seleccionar una fecha de entrega",
              validate: (value) => {
                if (!value) return true;
                const selected = new Date(value + "T00:00:00");
                const now = new Date(today + "T00:00:00");
                return selected >= now || "No puedes seleccionar una fecha anterior a hoy";
              },
            })}
          />
          {errors.fechaDespacho && (
            <span className="text-red-500 text-sm mt-1 block text-left">
              {errors.fechaDespacho.message}
            </span>
          )}
        </div>
        <div className="mb-5">
          <label className="block font-bold mb-2">Patente de camión</label>
          <input
            type="text"
            placeholder="Elige patente de camión"
            className="border border-gray-300 rounded-lg block w-full p-1"
            {...register("patenteCamion", { required: true })}
          />
        </div>
        <div className="mb-5">
          <label className="block font-bold mb-2">
            Orden de compra asociado
          </label>
          <input
            type="number"
            disabled={true}
            value={venta.idVenta}
            className="border border-gray-300 rounded-lg block w-full text-slate-400 p-1"
          />
        </div>
        <div className="mb-5">
          <label className="block font-bold mb-2">Dirección de entrega</label>
          <input
            type="text"
            disabled={true}
            value={venta.direccionCompra}
            className="border border-gray-300 rounded-lg block w-full text-slate-400 p-1"
          />
        </div>
        <div className="mb-5">
          <label className="block font-bold mb-2">Valor de compra</label>
          <input
            type="number"
            value={venta.valorCompra}
            className="border border-gray-300 rounded-lg block w-full text-slate-400 p-1"
            disabled={true}
          />
        </div>

        <button
          className="py-6 px-14 rounded-lg bg-teal-600 text-white font-bold mb-14"
          type="submit"
        >
          Asignar despacho
        </button>
      </form>
    </>
  );
};
