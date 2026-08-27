package com.example.whatsapp_clone

import android.provider.ContactsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Nome do canal precisa bater exatamente com o usado em
    // lib/core/native_contacts_service.dart.
    private val CANAL_CONTATOS = "casulo/contatos_nativo"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL_CONTATOS)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "listarContatos" -> {
                        // Roda numa Thread separada de propósito: é EXATAMENTE essa
                        // consulta (via flutter_contacts) que travava a thread
                        // principal e derrubava o app com ANR — mesmo com menos de
                        // 100 contatos na agenda e o WhatsApp oficial lendo a mesma
                        // agenda sem problema nenhum. Rodando em background e
                        // devolvendo o resultado na main thread (runOnUiThread),
                        // nunca trava a UI, no máximo demora.
                        Thread {
                            try {
                                val contatos = lerContatosDoProvider()
                                runOnUiThread { result.success(contatos) }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.error("ERRO_LEITURA_CONTATOS", e.message, null)
                                }
                            }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Consulta mínima e direta ao ContentResolver — só nome + número, sem
    // foto, sem propriedades extras, sem passar pela camada pesada de
    // nenhum plugin. É basicamente o que o Signal/Molly de verdade fazem.
    private fun lerContatosDoProvider(): List<Map<String, String>> {
        val lista = mutableListOf<Map<String, String>>()

        val projecao = arrayOf(
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
            ContactsContract.CommonDataKinds.Phone.NUMBER
        )

        val cursor = contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            projecao,
            null,
            null,
            null
        )

        cursor?.use {
            val idxNome = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
            val idxNumero = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)

            while (it.moveToNext()) {
                val nome = if (idxNome >= 0) (it.getString(idxNome) ?: "") else ""
                val numero = if (idxNumero >= 0) (it.getString(idxNumero) ?: "") else ""
                if (numero.isNotBlank()) {
                    lista.add(mapOf("nome" to nome, "numero" to numero))
                }
            }
        }

        return lista
    }
}
