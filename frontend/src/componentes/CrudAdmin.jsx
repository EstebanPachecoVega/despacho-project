import Navbar from "./Layouts/Navbar";
import Footer from "./Layouts/Footer";
import Carrusel from "./Layouts/Carrusel";

import { PruebaCards } from "./CrudAdmin/PruebaCards";
import Reviews from "./Layouts/Reviews";

export const CrudAdmin = () => {
  return (
    <>
      <div className="grid grid-cols-[auto_1fr] min-h-screen bg-gray-50">
        <div className="col-span-1">
          <Navbar />
        </div>

        <div className="overflow-y-auto p-6">
          <Carrusel />
          <PruebaCards />
          <Reviews />
          <Footer />
        </div>
      </div>
    </>
  );
};
