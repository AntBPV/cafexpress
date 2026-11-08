package com.cafexpress.backend.usuario.service;

import com.cafexpress.backend.usuario.dto.*;
import com.cafexpress.backend.usuario.entity.Usuario;
import com.cafexpress.backend.usuario.enums.Rol;
import com.cafexpress.backend.usuario.repository.UsuarioRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.util.UUID;

@Service
public class PerfilService {
    private final UsuarioRepository usuarios;
    public PerfilService(UsuarioRepository usuarios) { this.usuarios = usuarios; }

    public Usuario obtener(UUID id) {
        return usuarios.findById(id).filter(Usuario::isActivo)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "La cuenta no está activa."));
    }

    @Transactional(readOnly = true)
    public UsuarioResponse actual(UUID id) { return UsuarioResponse.desde(obtener(id)); }

    @Transactional
    public UsuarioResponse actualizarVendedor(UUID id, PerfilVendedorRequest request) {
        Usuario usuario = obtener(id);
        if (usuario.getRol() != Rol.VENDEDOR) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Solo el vendedor puede editar este perfil.");
        }
        usuario.completarPerfil(request.nombre(), request.empresaProductor(), request.paisOrigen());
        return UsuarioResponse.desde(usuario);
    }
}
