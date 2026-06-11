package com.citt.persistence.services;

import com.citt.exceptions.DespachoNotFoundException;
import com.citt.persistence.entity.Despacho;
import com.citt.persistence.repository.DespachoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Objects;
import java.util.Optional;

@Service
public class DespachoServiceImpl implements DespachoService{

    @Autowired
    private DespachoRepository despachoRepository;

    @Override
    public List<Despacho> findAllDespachos() {
        return despachoRepository.findAll();
    }

    @Override
    public Despacho saveDespacho(Despacho despacho) {
        return despachoRepository.save(despacho);
    }

    @Override
    public Despacho updateDespacho(Long idDespacho, Despacho despacho) {
        return despachoRepository.findById(idDespacho).map(existingDespacho -> {
            if (Objects.nonNull(despacho.getFechaDespacho())) {
                existingDespacho.setFechaDespacho(despacho.getFechaDespacho());
            }
            if (Objects.nonNull(despacho.getPatenteCamion()) && !despacho.getPatenteCamion().trim().isEmpty()) {
                existingDespacho.setPatenteCamion(despacho.getPatenteCamion());
            }
            existingDespacho.setIntento(despacho.getIntento());
            if (Objects.nonNull(despacho.getIdCompra())) {
                existingDespacho.setIdCompra(despacho.getIdCompra());
            }
            if (Objects.nonNull(despacho.getDireccionCompra()) && !despacho.getDireccionCompra().trim().isEmpty()) {
                existingDespacho.setDireccionCompra(despacho.getDireccionCompra());
            }
            if (Objects.nonNull(despacho.getValorCompra())) {
                existingDespacho.setValorCompra(despacho.getValorCompra());
            }
            existingDespacho.setDespachado(despacho.isDespachado());
            return despachoRepository.save(existingDespacho);
        }).orElseThrow(() -> new DespachoNotFoundException("Despacho no encontrado con ID: " + idDespacho));
    }

    @Override
    public void deleteDespacho(Long idDespacho) {
        Optional<Despacho> despacho = despachoRepository.findById(idDespacho);
        if(!despacho.isPresent()){
            throw new DespachoNotFoundException("¡No es posible eliminar! No existe despacho con el ID:" + idDespacho);
        }else {
            despachoRepository.deleteById(idDespacho);
        }
    }

    @Override
    public Despacho findById(Long idDespacho) {
        Optional<Despacho> despacho = despachoRepository.findById(idDespacho);
        if(!despacho.isPresent()) throw new DespachoNotFoundException("¡No existe despacho con el ID:" + idDespacho);
        return despacho.get();
    }
}
