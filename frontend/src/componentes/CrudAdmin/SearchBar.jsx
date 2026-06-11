export const SearchBar = ({ searchTerm, onSearch }) => {
  return (
    <>
      <section className="grid grid-cols-1 h-[120px] items-center justify-items-center">
        <div className="flex">
          <div className="flex gap-2">
            <input
              placeholder="Buscar por orden de compra o dirección..."
              type="text"
              value={searchTerm}
              onChange={(e) => onSearch(e.target.value)}
              className="bg-gray-50 border-2 border-gray-300 text-gray-900 text-sm rounded focus:ring-teal-300 focus:border-teal-300 block duration-500 w-[500px] h-[60px] p-2.5 outline-none"
            />
          </div>
        </div>
      </section>
    </>
  );
};
