import { useState } from "react";
import logo1 from "../../assets/images/logo1.png";
import logo2 from "../../assets/images/logo2.png";
import logo3 from "../../assets/images/logo3.png";

const slides = [
  { id: 1, src: logo1, alt: "Logo 1" },
  { id: 2, src: logo2, alt: "Logo 2" },
  { id: 3, src: logo3, alt: "Logo 3" },
];

function Carrusel() {
  const [current, setCurrent] = useState(0);

  const prev = () => setCurrent((c) => (c === 0 ? slides.length - 1 : c - 1));
  const next = () => setCurrent((c) => (c === slides.length - 1 ? 0 : c + 1));

  return (
    <div className="relative w-full mb-8">
      <div className="relative h-56 overflow-hidden rounded-lg md:h-80">
        {slides.map((slide, index) => (
          <div
            key={slide.id}
            className={`absolute w-full h-full transition-opacity duration-500 ${
              index === current ? "opacity-100" : "opacity-0"
            }`}
          >
            <img
              src={slide.src}
              alt={slide.alt}
              className="absolute block w-full h-full object-contain p-8"
            />
          </div>
        ))}
      </div>

      <div className="absolute z-30 flex -translate-x-1/2 bottom-3 left-1/2 space-x-3">
        {slides.map((_, index) => (
          <button
            key={index}
            type="button"
            onClick={() => setCurrent(index)}
            className={`w-3 h-3 rounded-full ${
              index === current ? "bg-teal-600" : "bg-gray-300"
            }`}
            aria-label={`Slide ${index + 1}`}
          />
        ))}
      </div>

      <button
        type="button"
        onClick={prev}
        className="absolute top-0 start-0 z-30 flex items-center justify-center h-full px-4 cursor-pointer group"
      >
        <span className="inline-flex items-center justify-center w-10 h-10 rounded-full bg-white/50 group-hover:bg-white/80">
          <svg className="w-4 h-4 text-gray-800" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 6 10">
            <path stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 1 1 5l4 4" />
          </svg>
        </span>
      </button>
      <button
        type="button"
        onClick={next}
        className="absolute top-0 end-0 z-30 flex items-center justify-center h-full px-4 cursor-pointer group"
      >
        <span className="inline-flex items-center justify-center w-10 h-10 rounded-full bg-white/50 group-hover:bg-white/80">
          <svg className="w-4 h-4 text-gray-800" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 6 10">
            <path stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="m1 9 4-4-4-4" />
          </svg>
        </span>
      </button>
    </div>
  );
}

export default Carrusel;
